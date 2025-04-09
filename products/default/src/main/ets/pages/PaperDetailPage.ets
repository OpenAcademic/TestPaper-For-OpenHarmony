import { promptAction, router } from '@kit.ArkUI';
import { ArxivConfigBuilder, ArxivType, downloadPDF, getPapers } from '../api/ArxivApi';
import { stoage, store } from '../defaultability/DefaultAbility';
import { ArxivPaper } from '../entity/ArxivPaper';
import { Paper } from '../entity/Paper';
import { BottomTools, BottomTools2 } from '../widget/BottonTools';
import { BusinessError } from '@kit.BasicServicesKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

class Config{
  id:string
  constructor(id:string) {
    this.id=id
  }
}
@Entry(stoage)
@Component
struct PaperDetailPage {
  @LocalStorageLink("id") message: string = '';
  @State is_loading : boolean = false
  @State info : ArxivPaper | null = null
  @State bid : string = ''
  private context = getContext() as common.UIAbilityContext;
  @StorageProp('bottomRectHeight')
  bottomRectHeight: number = 0;
  @StorageProp('topRectHeight')
  topRectHeight: number = 0;
  async loading(){
    this.is_loading = true
    console.log("res",this.message)
    const res = await getPapers(ArxivConfigBuilder(ArxivType.ID,this.bid).toTiaojianString())
    if (res && res.length>0){
      console.log("bid",res[0])

      this.info = res[0]
      this.is_loading = false
    }
    else{
      promptAction.showToast({
        message:"尚未找到",
        duration:2000
      })
      this.is_loading = false
    }
  }

  async aboutToAppear() {
    let lists = this.message.split("/")
    this.bid=lists[lists.length-1]
    let lists2 = this.bid.split("v")
    this.bid=lists2[0]

    await this.loading()
  }
  build() {
    RelativeContainer() {
      if (this.is_loading){
        Column(){
          Row(){
            LoadingProgress().size({width:150,height:150})

          }.width('100%').height('100%').alignItems(VerticalAlign.Center).justifyContent(FlexAlign.Center)

        }.width('100%').height('100%').alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)

      } else{
        if (this.info){
          Stack(){
            Column(){
              Scroll(){
                Column() {
                  Text("Arxiv."+this.info.id.split("/")[this.info.id.split("/").length-1])
                    .margin(5)
                    .fontSize(15)
                    .textAlign(TextAlign.Start)
                    .fontStyle(FontStyle.Italic)
                    .width('90%')
                    .textOverflow({overflow:TextOverflow.Ellipsis})
                    .fontColor($r('sys.color.ohos_id_color_text_primary'))
                  Text(this.info.title)
                    .margin({
                      left:5,
                      right:5,
                      bottom:10
                    })
                    .fontSize(24).fontWeight(FontWeight.Bolder)
                    .textAlign(TextAlign.Start).wordBreak(WordBreak.BREAK_ALL)
                    .width('90%')
                    .textOverflow({overflow:TextOverflow.Ellipsis})
                    .fontColor($r('sys.color.ohos_id_color_text_primary'))
                  Text(this.info.author?.join(","))
                    .margin(5)
                    .fontSize(15)
                    .textAlign(TextAlign.Start)
                    .fontStyle(FontStyle.Italic)
                    .width('90%')
                    .textOverflow({overflow:TextOverflow.Ellipsis})
                    .fontColor($r('sys.color.ohos_id_color_text_primary'))
                  Text(this.info.summary?.replaceAll("\n"," "))
                    .margin(5)
                    .fontSize(20).wordBreak(WordBreak.BREAK_ALL)
                    .textAlign(TextAlign.Start)
                    .width('90%')
                    .textOverflow({overflow:TextOverflow.Ellipsis})
                    .fontColor($r('sys.color.ohos_id_color_text_primary'))
                  if (this.info.doi){
                    Text("DOI:"+this.info.doi)
                      .margin(5)
                      .fontSize(15)
                      .textAlign(TextAlign.Start)
                      .fontStyle(FontStyle.Italic)
                      .width('90%')
                      .textOverflow({overflow:TextOverflow.Ellipsis})
                      .fontColor($r('sys.color.ohos_id_color_text_primary'))
                  }

                }.width('100%').alignItems(HorizontalAlign.Start).justifyContent(FlexAlign.Start)
              }.width('100%')
              .height('85%')

              BottomTools2({
                aid:this.info?.id,
                onDelete:async ()=>{
                  if (store){
                    console.info("delete")
                    let aid = this.info?.id
                    if (aid){
                      const result = await promptAction.showDialog({
                        message: '确定要删除吗？',
                        buttons: [
                          { text: '取消', color: '#FF0000' },
                          { text: '确认', color: '#0099FF' }
                        ]
                      })
                      if (result.index === 0) {
                        console.info('User canceled the operation.');
                      } else if (result.index === 1) {
                        Paper.delete_arxiv_paper(store,aid)
                        console.info('User confirmed the operation.');
                        promptAction.showToast({
                          message:"删除成功",
                          duration:2000
                        })

                      }

                    }

                  }
                },
                onRead:async ()=> {
                  let context = this.context
                  if (this.info?.licenses){
                    let uri =await downloadPDF(this.info?.licenses, this.context, this.info?.id)
                    console.info("uri:"+uri)
                    router.pushUrl({
                      url: "pages/PDFReaderPage",
                      params: {
                        url: uri
                      }
                    })
                  }
                },
                onShare : ()=>{
                  let shareData: systemShare.SharedData = new systemShare.SharedData({
                    utd: uniformTypeDescriptor.UniformDataType.TEXT,
                    content: this.info?.title+"\n"+this.info?.summary?.replaceAll("\n"," "),
                    title:  this.info?.title,
                    description:  this.info?.title+"\n"+this.info?.summary?.replaceAll("\n"," "),
                    // thumbnail: new Uint8Array() // 推荐传入适合的缩略图 不传则显示默认text图标
                  });
                  // 进行分享面板显示
                  let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
                  let context = getContext(this) as common.UIAbilityContext;
                  controller.show(context, {
                    selectionMode: systemShare.SelectionMode.SINGLE,
                    previewMode: systemShare.SharePreviewMode.DETAIL,
                  }).then(() => {
                    console.info('ShareController show success.');
                  }).catch((error: BusinessError) => {
                    console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
                  });
                },
                onSave:async ()=>{

                  if (store){
                    console.info("save")
                    Paper.insert_arxiv_paper(store,this.info!)
                    promptAction.showToast({
                      message:"保存成功",
                      duration:2000
                    })


                  }

                },
                onBackHome: ()=>{
                  router.back()
                  router.pushUrl({
                    url:'pages/ResponsiveIndex'
                  })
                }
              }).width('90%').margin(5)




            }.width('100%')
            .height('100%').alignItems(HorizontalAlign.Start).justifyContent(FlexAlign.SpaceBetween)

          }.alignContent(Alignment.TopStart).margin(20)
          .width('100%')
          .height('100%')
        }
        else{

          Column(){
            Image($r('app.media.empty')).size({width:250,height:250})
            Text("内容为空")
              .margin(5)
              .fontSize(24)
              .textAlign(TextAlign.Center)
              .width('100%')
              .textOverflow({overflow:TextOverflow.Ellipsis})
              .fontColor($r('sys.color.ohos_id_color_text_primary'))


          }.width('100%').height('100%').alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)

        }
      }


    }
    .height('100%')
    .width('100%')
  }
}