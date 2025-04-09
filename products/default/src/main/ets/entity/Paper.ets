import systemDateTime from "@ohos.systemDateTime"
import { relationalStore } from "@kit.ArkData";
import { ArxivPaper } from "./ArxivPaper";


/***
 * 获取 测试的 论文
 */

/***
 * 时间转字符串
 * @param timestamp 时间戳
 * @returns 时间字符串
 */
export function paperTime2Str(timestamp?:number){
  console.log("timestamp"+timestamp)
  if (timestamp==null){
    const date = new Date(systemDateTime.getTime(true));
    const formattedDate = date.toLocaleString();
    return formattedDate
  }else{
    const date = new Date(timestamp * 1000);
    const formattedDate = date.toLocaleString();
    return formattedDate
  }
}

@Observed
export class Paper {
  title: string
  abstract: string
  keywords: string
  author: string
  arxiv_id: string
  doi?: string
  jourly?: string
  status: number = 0
  creatTime?: number = 0
  updateTime?: number = 0
  publishTime?: number = 0


  constructor(
    aid: string,
    title: string,
    ab: string,
    kw: string,
    authors: string, status: number,
     di?: string, jourly?: string,
    creatTime?: number, updateTime?: number, publishTime?: number
  ) {
    this.arxiv_id = aid
    this.title = title
    this.abstract = ab
    this.keywords = kw
    this.arxiv_id = aid
    this.doi = di
    this.author = authors
    this.jourly = jourly

    this.status = status
    this.publishTime = publishTime
    this.creatTime = creatTime
    this.updateTime = updateTime

  }

  /**
   * 构建创建论文表的SQL语句并执行
   *
   * @param store 关系型数据库存储对象
   * @returns 执行结果
   */
  static build_create_table_sql(store: relationalStore.RdbStore) {
    let createTableSql = `CREATE TABLE IF NOT EXISTS paper ( `;
    createTableSql += `aid TEXT UNIQUE PRIMARY KEY, `;

    createTableSql += `title TEXT, `;
    createTableSql += `abstract TEXT, `;
    createTableSql += `keywords TEXT, `;
    createTableSql += `authors TEXT, `;

    createTableSql += `status INTEGER NOT NULL DEFAULT 0, `;

    createTableSql += `doi TEXT, `;
    createTableSql += `jourly TEXT, `;
    createTableSql += `publishTime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, `;
    createTableSql += `creatTime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, `;
    createTableSql += `updateTime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP`;

    createTableSql += `)`;

    return store.executeSync(createTableSql)
  }


  /**
   * 将论文信息插入到数据库中
   *
   * @param store 关系型数据库存储对象
   * @param paper 论文对象，包含论文的相关信息
   * @returns 执行结果
   */
  static insert_paper(store: relationalStore.RdbStore, paper: Paper): number {
    // 检查 cid 是否已经存在
    let predicates = new relationalStore.RdbPredicates("paper");
    predicates.equalTo("aid", paper.arxiv_id);
    let resultSet: relationalStore.ResultSet = store.querySync(predicates, ["id"]);
    if (resultSet.rowCount > 0) {
      return -1;
    }


    if (!paper.doi) {
      paper.doi = ""
    }
    if (!paper.publishTime) {
      paper.publishTime = systemDateTime.getTime(true)
    }
    if (!paper.jourly) {
      paper.jourly = ""
    }

    if (!paper.arxiv_id) {
      paper.arxiv_id = ""
    }
    if (!paper.creatTime) {
      paper.creatTime = systemDateTime.getTime(true)
    }
    if (!paper.updateTime) {
      paper.updateTime = systemDateTime.getTime(true)
    }
    const valueBucket3: relationalStore.ValuesBucket = {
      "title": paper.title,
      "abstract": paper.abstract.replaceAll("\n",""),
      "keywords": paper.keywords,
      "authors": paper.author,
      "status": paper.status,
      "doi": paper.doi,
      "aid": paper.arxiv_id,
      "jourly": paper.jourly,
      "publishTime": paper.publishTime,
      "creatTime": paper.creatTime,
      "updateTime": paper.updateTime,
    };
    if(store != undefined) {
      try {
        let rowId : number = (store as relationalStore.RdbStore).insertSync("paper", valueBucket3);
        console.info(`Insert is successful, rowId = ${rowId}`);
        return rowId
      } catch (error) {
        console.error(`Insert is failed, code is ${error.code},message is ${error.message}`);
        return -1
      }
    }else{
      return -1
    }


  }

  /**
   * 将Arxiv论文信息插入到数据库中
   *
   * @param store 关系型数据库存储对象
   * @param arxivPaper Arxiv论文对象，包含论文的相关信息
   * @returns 插入操作的结果值
   */
  static insert_arxiv_paper(store: relationalStore.RdbStore, arxivPaper: ArxivPaper): relationalStore.ValueType {
    if (!arxivPaper.summary) {
      arxivPaper.summary = ""
    }
    if (!arxivPaper.author) {
      arxivPaper.author = []
    }
    if (!arxivPaper.journal) {
      arxivPaper.journal = "Arxiv"
    }
    if (!arxivPaper.category) {
      arxivPaper.category = []
    }
    if (! arxivPaper.licenses) {
      arxivPaper.licenses = ""
    }
    console.log("arxivPaper", arxivPaper.id)
    let paper = new Paper(
      arxivPaper.id,
      arxivPaper.title,
      arxivPaper.summary.toString().replace("\n",""),
      arxivPaper.licenses,
      arxivPaper.author?.join(","),
      0,

      arxivPaper.doi,
      arxivPaper.journal,
      systemDateTime.getTime(true),
      systemDateTime.getTime(true),
      arxivPaper.updated
    )
    console.log("sds", paper)
    return Paper.insert_paper(store, paper)
  }

  /**
   * 根据Arxiv ID检查是否存在对应的论文
   *
   * @param store 关系型数据库存储对象
   * @param arxiv_id Arxiv ID
   * @returns 如果存在对应的论文则返回true，否则返回false
   */
  static async get_isExistByArxivId(store: relationalStore.RdbStore, arxiv_id: string): Promise<boolean> {
    let predicates = new relationalStore.RdbPredicates("paper");
    predicates.equalTo("aid", arxiv_id);
    let resultSet: relationalStore.ResultSet = store.querySync(predicates,
      ["aid"]);
    return resultSet.rowCount > 0
  }

  /**
   * 根据页码获取论文列表
   *
   * @param store 关系型数据库存储对象
   * @param pageNum 页码，从1开始
   * @returns 论文列表
   */
  static async get_papers_by_page(store: relationalStore.RdbStore, pageNum: number): Promise<Paper[]> {
    let predicates = new relationalStore.RdbPredicates("paper");
    predicates.orderByDesc("publishTime")
    if (pageNum > 0) {
      const pageSize = 10;
      predicates.offsetAs((pageNum - 1) * pageSize).limitAs(pageSize);
    }
    let resultSet: relationalStore.ResultSet = store.querySync(predicates,
      ["aid","title", "abstract", "keywords", "authors", "status",  "doi", "jourly", "publishTime", "creatTime",
        "updateTime"]);
    ;

    let list: Paper[] = []
    while (resultSet.goToNextRow()) {
      list.push(
        new Paper(
          resultSet.getString(resultSet.getColumnIndex("aid")),
          resultSet.getString(resultSet.getColumnIndex("title")),
          resultSet.getString(resultSet.getColumnIndex("abstract")),
          resultSet.getString(resultSet.getColumnIndex("keywords")),
          resultSet.getString(resultSet.getColumnIndex("authors")),
          resultSet.getLong(resultSet.getColumnIndex("status")),
          resultSet.getString(resultSet.getColumnIndex("doi")),
          resultSet.getString(resultSet.getColumnIndex("jourly")),
          resultSet.getLong(resultSet.getColumnIndex("creatTime")),
          resultSet.getLong(resultSet.getColumnIndex("updateTime")),
          resultSet.getLong(resultSet.getColumnIndex("publishTime"))

        )
      )
    }


    return list;

  }


  /**
   * 根据Arxiv ID删除对应的论文
   *
   * @param store 关系型数据库存储对象
   * @param arxiv_id Arxiv ID
   * @returns 如果删除成功则返回true，否则返回false
   * @throws 如果删除过程中发生错误，会抛出异常并输出错误信息
   */
  static async delete_arxiv_paper(store: relationalStore.RdbStore, arxiv_id: string): Promise<boolean> {
    let predicates = new relationalStore.RdbPredicates("paper");
    predicates.equalTo("aid", arxiv_id);
    try{
      store.deleteSync(predicates)
      return true
    }catch (e){
      console.error(`Delete is failed, code is ${e.code},message is ${e.message}`);
      return false
    }
  }
}

