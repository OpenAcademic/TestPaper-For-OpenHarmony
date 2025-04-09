import { http } from "@kit.NetworkKit";
import { ArxivBase, ArxivPaper } from "../entity/ArxivPaper";
import { BusinessError, request, systemDateTime } from "@kit.BasicServicesKit";
import { abilityAccessCtrl, common, PermissionRequestResult } from "@kit.AbilityKit";
import { fileIo, picker } from "@kit.CoreFileKit";
import { notificationManager } from "@kit.NotificationKit";
import { Environment } from '@kit.CoreFileKit';
import { buildNotifyTemp, checkPermissionGrant, permissions, requestNotifiesPers } from "./per";
import { when } from "@ohos/hypium";

export let arxivTypeLabels : string[] = [
  "标题",
  "作者",
  "摘要",
  "评论",
  "期刊",
  "子分类",
  "报告",
  "ID",
]
export function getArxivType(index:number):ArxivType{
  if (index<0||index>arxivTypeLabels.length){
    return ArxivType.ALL
  }
  if (index===0){
    return ArxivType.TITTLE
  } else if (index===1){
    return ArxivType.AUTHOR
  } else if (index===2){
    return ArxivType.ABSTRACT
  } else if (index===3){
    return ArxivType.COMMENT
  } else if (index===4){
    return ArxivType.JOURNAL
  } else if (index===5){
    return ArxivType.SUBCATEGORY
  } else if (index===6){
    return ArxivType.REPORT
  } else if (index===7){
    return ArxivType.ID
  } else{
    return ArxivType.ALL
  }

}
export enum ArxivType{
  TITTLE,
  AUTHOR,
  ABSTRACT,
  COMMENT,
  JOURNAL,
  SUBCATEGORY,
  REPORT,
  ID,
  ALL
}

export class ArxivConfig{
  type:ArxivType = ArxivType.TITTLE
  value:string = ""
  strs:string = ""
  constructor(
    type:ArxivType,value:string
  ) {
    this.type = type;
    this.value = value;
  }
  toTiaojianString() : string{
    /**
     * ti	Title
     au	Author
     abs	Abstract
     co	Comment
     jr	Journal Reference
     cat	Subject Category
     rn	Report Number
     id	Id (use id_list instead)
     all	All of the above
     */
    let p = ""
    if (this.type==ArxivType.AUTHOR){
      p = "au:"+this.value
    } else if (this.type==ArxivType.TITTLE){
      p = "ti:"+this.value
    } else if (this.type==ArxivType.ABSTRACT){
      p = "abs:"+this.value
    }else if (this.type==ArxivType.COMMENT){
      p = "co:"+this.value
    }else if (this.type==ArxivType.JOURNAL){
      p = "jr:"+this.value
    }else if (this.type==ArxivType.SUBCATEGORY){
      p = "cat:"+this.value
    }else if (this.type==ArxivType.REPORT){
      p = "rn:"+this.value
    }else if (this.type==ArxivType.ID){
      p = "id:"+this.value
    }else if (this.type==ArxivType.ALL){
      p = "all:"+this.value
    } else{
    }

    return p

  }

  and(config2:ArxivConfig) : string {
    this.strs = this.toTiaojianString() + "+AND+" + config2.toTiaojianString()
    return this.strs
  }

  or(config2:ArxivConfig): string  {
    this.strs = this.toTiaojianString() + "+OR+" + config2.toTiaojianString()
    return this.strs
  }

  andnot(config2:ArxivConfig) : string {
    this.strs = this.toTiaojianString() + "+ANDNOT+" + config2.toTiaojianString()
    return this.strs
  }


}

export function ArxivConfigBuilder(
  type:ArxivType,value:string
){
  return new ArxivConfig(type,value)
}
function getUserDirExample() {
  try {
    const downloadPath = Environment.getUserDownloadDir();
    console.info(`success to getUserDownloadDir: ${downloadPath}`);
    const documentsPath = Environment.getUserDocumentDir();
    console.info(`success to getUserDocumentDir: ${documentsPath}`);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`failed to get user dir, because: ${JSON.stringify(err)}`);
  }
}
export async function downloadPDF(
  url:string,context:common.UIAbilityContext,
  arxiv_id : string = "",
) : Promise<string> {

  let all_aid = url.split("/")
  let arxiv_id_str = all_aid[all_aid.length - 1]
  console.info("arxiv_id_str", arxiv_id_str)

  let fimeName = arxiv_id_str + ".pdf"
  let notify_id = Number((Math.random()*1000).toFixed(0))
  if (await requestNotifiesPers(context)){
    let temp = buildNotifyTemp(notify_id, "下载进度：0%", "正在下载"+arxiv_id_str,0)

    notificationManager.publish(temp, (err: BusinessError) => {
      if (err) {
        return;
      }
    });
  }
  return new Promise<string>( (resolve, reject) => {


      let filePath = context.tempDir + '/' + fimeName

      console.info(filePath)
      // 检查文件是否存在
      let res = fileIo.accessSync(filePath);
      console.info(""+url)

      if (res) {
        console.info("file exist")
        resolve(filePath)
      }
      else{

        request.downloadFile(context, {
          enableMetered: true,
          url: url+ ".pdf",
          filePath: filePath
        })
          .then((downloadTask) => {
            downloadTask.on('fail', (err: number) => {
              console.error(`Failed to download the task. Code: ${err}`);
            });
            downloadTask.on('progress', (receivedSize: number, totalSize: number) => {
              let per = Number(
                ((receivedSize/totalSize)*100).toFixed(0)
              )
              let temp = buildNotifyTemp(notify_id, "下载进度:"+per.toString()+"%", "正在下载"+arxiv_id_str,per)
              notificationManager.publish(temp, (err: BusinessError) => {
                if (err) {
                  return;
                }
              });
              console.log('download', "receivedSize:" + (receivedSize/1024) + " totalSize:" + (totalSize / 1024));
            });
            downloadTask.on('complete', () => {

              notificationManager.cancel(notify_id)
              resolve(filePath)
            })
          }).catch(() => {
          console.error("downloadFile error: ")
          reject()
        })
      }




  })
}

export async function getPapers(strs: string): Promise<ArxivPaper[] | null> {
  let httpRequest = http.createHttp();
  // 将 空格转义
  let url_strs = encodeURIComponent(strs)
  let uri = "https://note.wxd2zrx.top/search_arxiv"

  console.info("vdf",uri)

  try {
    let response = await httpRequest.request(
      uri,
      {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json'
        },
        extraData: JSON.stringify({
          strs: strs
        })
      }
    )

    if (response.responseCode === 200) {
      console.info("vdf",response.result.toString())
      let result = JSON.parse(response.result.toString()) as ArxivBase
      return result.data as ArxivPaper[]
    }
    return null
  } catch (err) {
    console.error(`Failed to parse code: ${err.code}`)
    return null
  } finally {
    httpRequest.destroy()
  }
}