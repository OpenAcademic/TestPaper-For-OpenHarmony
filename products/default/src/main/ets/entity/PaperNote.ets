import systemDateTime from "@ohos.systemDateTime"
import { relationalStore } from "@kit.ArkData";
import { ArxivPaper } from "./ArxivPaper";



@Observed
export class PaperNote {
  id: number
  aid: string
  ind:number
  pind:number
  select_info: string
  trans_res:string
  user_note?: string = ""
  creatTime?: number = 0
  updateTime?: number = 0


  constructor(
    id: number,
    aid: string,
    index:number,
    pindex:number,
    select_info: string,
    trans_res: string,user_note?: string,
    creatTime?: number, updateTime?: number
  ) {
    this.id = id
    this.aid = aid
    this.ind = index
    this.pind = pindex
    this.select_info = select_info
    this.trans_res = trans_res
    this.user_note = user_note

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
    let createTableSql = `CREATE TABLE IF NOT EXISTS paper_note ( `;
    createTableSql += `id INTEGER PRIMARY KEY AUTOINCREMENT, `;
    createTableSql += `aid TEXT UNIQUE, `;
    createTableSql += `ind INTEGER , `;
    createTableSql += `pind INTEGER , `;


    createTableSql += `select_info TEXT, `;
    createTableSql += `trans_res TEXT, `;
    createTableSql += `user_note TEXT, `;

    createTableSql += `updateTime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, `;
    createTableSql += `creatTime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP `;
    createTableSql += `)`;
    console.log("sql",createTableSql)
    return store.executeSync(createTableSql)
  }


  /**
   * 将论文信息插入到数据库中
   *
   * @param store 关系型数据库存储对象
   * @param paper 论文
   * @returns 执行结果
   */
  static insert_paper(store: relationalStore.RdbStore, paper: PaperNote): number {

    // 获取最后一个 id
    let predicates2 = new relationalStore.RdbPredicates("paper_note");
    let resultSet2 = store.querySync(predicates2, ["id"]);
    let lastid = 0
    if (resultSet2.rowCount == 0) {
      lastid = 1
    } else {
      resultSet2.goToLastRow()
      lastid = resultSet2.getLong(0) + 1
    }
    if (!paper.user_note) {
      paper.user_note = ""
    }

    if (!paper.creatTime) {
      paper.creatTime = systemDateTime.getTime(true)
    }
    if (!paper.updateTime) {
      paper.updateTime = systemDateTime.getTime(true)
    }


    const valueBucket3: relationalStore.ValuesBucket = {
      "id": lastid,
      "aid": paper.aid,
      "ind":paper.ind,
      "pind":paper.pind,
      "trans_res": paper.trans_res,
      "select_info": paper.select_info,
      "user_note": paper.user_note,

      "creatTime": paper.creatTime,
      "updateTime": paper.updateTime,
    };
    if (store != undefined) {
      try {
        let rowId: number = (store as relationalStore.RdbStore).insertSync("paper_note", valueBucket3);
        console.info(`Insert is successful, rowId = ${rowId}`);
        return rowId
      } catch (error) {
        console.error(`Insert is failed, code is ${error.code},message is ${error.message}`);
        return -1
      }
    } else {
      return -1
    }
  }
  /**
   * 从数据库中删除指定 ID 的批注
   *
   * @param store 关系型数据库存储对象
   * @param id 要删除的批注 ID
   * @returns 删除是否成功
   */
  static async delete_paper(store: relationalStore.RdbStore, id: number): Promise<boolean> {
    let predicates = new relationalStore.RdbPredicates("paper_note");
    predicates.equalTo("id", id);
    try{
      let deleteRows = store.deleteSync(predicates);
      console.info(`Delete is successful, affected rows = ${deleteRows}`);
      return deleteRows > 0;
    } catch (error) {
      console.error(`Delete failed, code is ${error.code}, message is ${error.message}`);
      return false;
    }
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
      ["id"]);
    return resultSet.rowCount > 0
  }


  static async getPaperNotesByAid(store: relationalStore.RdbStore, arxiv_id: string) : Promise<PaperNote[]>{
    let predicates = new relationalStore.RdbPredicates("paper_note");
    let lists = arxiv_id.split("/")
    predicates.equalTo("aid", lists[lists.length-1]);

    let resultSet: relationalStore.ResultSet = store.querySync(predicates,
      ["id", "aid","ind","pind", "select_info", "trans_res", "user_note", "creatTime", "updateTime"]);



    let list: PaperNote[] = []
    while (resultSet.goToNextRow()) {
      list.push(
        new PaperNote(
          resultSet.getLong(resultSet.getColumnIndex("id")),
          resultSet.getString(resultSet.getColumnIndex("aid")),
          resultSet.getLong(resultSet.getColumnIndex("ind")),
          resultSet.getLong(resultSet.getColumnIndex("pind")),

          resultSet.getString(resultSet.getColumnIndex("select_info")),
          resultSet.getString(resultSet.getColumnIndex("trans_res")),
          resultSet.getString(resultSet.getColumnIndex("user_note")),
          resultSet.getLong(resultSet.getColumnIndex("creatTime")),
          resultSet.getLong(resultSet.getColumnIndex("updateTime")),
        )
      )
    }

    return list;


  }


}

