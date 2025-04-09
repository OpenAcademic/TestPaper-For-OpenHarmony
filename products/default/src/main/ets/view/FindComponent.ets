import { Paper } from "../entity/Paper";

import * as CommonConstants from '../constants/CommonConstants';
import { BreakPointType } from "@ohos/common";
import { ArxivPaper } from "../entity/ArxivPaper";
import { ArxivConfig, ArxivConfigBuilder, ArxivType, downloadPDF, getPapers } from "../api/ArxivApi";
import { LMICallBack, lvMarkdownIn } from "@luvi/lv-markdown-in"
import { WebComponent, WebObj } from "../widget/WebView";
import { webview } from "@kit.ArkWeb";
import { text2rich } from "../viewmodel/RichTextExport";
import { BottomTools } from "../widget/BottonTools";
import { dataPreferences, store } from "../defaultability/DefaultAbility";
import { promptAction, router } from "@kit.ArkUI";
import { common, Want, wantConstant } from "@kit.AbilityKit";
import { uniformTypeDescriptor } from "@kit.ArkData";
import { systemShare } from "@kit.ShareKit";
import { BusinessError } from "@kit.BasicServicesKit";
import { fileIo, fileUri } from "@kit.CoreFileKit";
import { UserInfo } from "./MinePage";

@Component
export struct FindComponent {
  @State data: ArxivPaper[] = [];
  @State isShow: boolean[] = [];

  @State private is_loading : boolean = false
  @StorageProp('mainBreakpoint') currentBreakpoint: string = CommonConstants.BREAKPOINTS_INITIALIZE_NAME;
  @State colTemplate: string = CommonConstants.INITIALIZE_TEMPLATE;
  @State selectPaper : ArxivPaper | null = null
  webcontroller : webview.WebviewController = new webview.WebviewController();
  @State user:UserInfo|null=null

  @Builder
  myBuilder() {
    Stack(){
      if (this.selectPaper){
        Column(){
          Scroll(){
            Column() {
              Text(this.selectPaper?.id)
                .margin(5)
                .fontSize(15)
                .textAlign(TextAlign.Start)
                .fontStyle(FontStyle.Italic)
                .width('90%')
                .textOverflow({overflow:TextOverflow.Ellipsis})
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
              Text(this.selectPaper?.title)
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
              Text(this.selectPaper?.author?.join(","))
                .margin(5)
                .fontSize(15)
                .textAlign(TextAlign.Start)
                .fontStyle(FontStyle.Italic)
                .width('90%')
                .textOverflow({overflow:TextOverflow.Ellipsis})
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
              Text(this.selectPaper?.summary?.replaceAll("\n"," "))
                .margin(5)
                .fontSize(20).wordBreak(WordBreak.BREAK_ALL)
                .textAlign(TextAlign.Start)
                .width('90%')
                .textOverflow({overflow:TextOverflow.Ellipsis})
                .fontColor($r('sys.color.ohos_id_color_text_primary'))

              if (this.selectPaper?.doi){
                Text("DOI:"+this.selectPaper?.doi)
                  .margin(5)
                  .fontSize(15)
                  .textAlign(TextAlign.Start)
                  .fontStyle(FontStyle.Italic)
                  .width('90%')
                  .textOverflow({overflow:TextOverflow.Ellipsis})
                  .fontColor($r('sys.color.ohos_id_color_text_primary'))
              }

            }.width('100%').alignItems(HorizontalAlign.Start)
          }.width('100%')
          .height('85%')

          
          if (this.selectPaper){
            BottomTools({
              aid:this.selectPaper.id,
              onDelete:async ()=>{
                if (store){
                  console.info("delete")
                  let aid = this.selectPaper?.id
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
                      this.isShow[this.data.findIndex(item=>item.id === aid)] = false

                    }

                  }

                }
              },
              onRead:async ()=> {
                let context = getContext() as common.UIAbilityContext;
                if (this.selectPaper?.licenses){
                  let uri =await downloadPDF(this.selectPaper?.licenses, context, this.selectPaper?.id)

                  console.info("arxiv_id_str",  this.selectPaper?.id)
                  let myuri = fileUri.getUriFromPath(uri)

                  console.info("uri:"+" file:/"+myuri)

                  let wantInfo: Want = {
                    uri: myuri,
                    type: "application/pdf", // 表示待打开文件的类型
                    flags: wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION |
                    wantConstant.Flags.FLAG_AUTH_WRITE_URI_PERMISSION
                  }


                  context.startAbility(wantInfo).then(() => {
                  }).catch((err: BusinessError) => {
                  })
                }
              },
              onShare : ()=>{
                let shareData: systemShare.SharedData = new systemShare.SharedData({
                  utd: uniformTypeDescriptor.UniformDataType.TEXT,
                  content: this.selectPaper?.title+"\n"+this.selectPaper?.summary?.replaceAll("\n"," "),
                  title:  this.selectPaper?.title,
                  description:  this.selectPaper?.title+"\n"+this.selectPaper?.summary?.replaceAll("\n"," "),
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
                  Paper.insert_arxiv_paper(store,this.selectPaper!)
                  promptAction.showToast({
                    message:"保存成功",
                    duration:2000
                  })
                  this.isShow[this.data.findIndex(item=>item.id === this.selectPaper?.id)] = false

                }

              }
            }).width('95%').margin(5)
          }


        }.width('100%')
        .height('100%').alignItems(HorizontalAlign.Start).justifyContent(FlexAlign.SpaceBetween)

      }

    }.alignContent(Alignment.TopStart).margin(20)
    .width('95%')
    .height('100%')


  }
  async aboutToAppear() {
    console.log("dfgg",ArxivConfigBuilder(ArxivType.TITTLE,"dfdf").and(ArxivConfigBuilder(ArxivType.ABSTRACT,"dfdsf")))
    if (dataPreferences){
      const usertext = dataPreferences.getSync("user","") as string
      if(usertext){
        this.user=JSON.parse(usertext) as UserInfo
      }
    }
    let result : ArxivPaper[] | null = null
    if (this.user){
      if (this.user.desp){
        result = await getPapers(
          new ArxivConfig(ArxivType.ALL,this.user.desp).toTiaojianString())
      }else{
        result = await getPapers(new ArxivConfig(ArxivType.ALL,"").toTiaojianString())
      }

    }else{
      result = await getPapers(new ArxivConfig(ArxivType.ALL,"").toTiaojianString())
    }


    if (result){
      console.info("vdf",result.toString())
      this.data = result
      for (let i = 0; i < result.length; i++) {
        this.isShow.push(false)
      }
      this.is_loading = true
    }


  }
  build() {
    Column(){
      Image($r('app.media.search_logo')).width('200vp')

      Row(){
        Search({
          placeholder:"点击搜索Arxiv论文"
        }).width('100%').onSubmit(e=>{

        }).searchButton("搜索").onClick(e=>{
          router.pushUrl({
            url:"pages/SearchPage"
          })
        }).onFocus(()=>{

        })
      }.width('90%')
      if (!this.is_loading){
        LoadingProgress().size({width:50,height:50})
      }else{
        if (this.data.length>0){
          Scroll(){
            Column(){
              Text("相关Arxiv论文")
                .maxLines(1)
                .margin({bottom:10,top:10})
                .fontSize(25)
                .fontColor(Color.Red)
                .textAlign(TextAlign.Center)
                .fontWeight(FontWeight.Bolder)
                .width('90%')
                .textOverflow({overflow:TextOverflow.Ellipsis})
              Grid() {
                ForEach(this.data, (paper:ArxivPaper,index) => {
                  GridItem() {
                    Row(){
                      Text((index+1).toString()+". ")
                        .fontSize(12)
                        .textAlign(TextAlign.Start)
                        .fontStyle(FontStyle.Italic)
                        .textOverflow({overflow:TextOverflow.Ellipsis})
                        .fontColor($r('sys.color.ohos_id_color_text_primary'))
                      Text(paper.title)
                        .fontSize(12).maxLines(1)
                        .textAlign(TextAlign.Start)
                        .fontStyle(FontStyle.Italic)
                        .textOverflow({overflow:TextOverflow.Ellipsis})
                        .fontColor($r('sys.color.ohos_id_color_text_primary'))
                    }.width('100%').justifyContent(FlexAlign.Start).margin(5)
                    .padding(5)
                    .borderRadius(20)
                    .width('100%')
                    .bindSheet(this.isShow[index], this.myBuilder(), {
                      detents: [SheetSize.LARGE],
                      backgroundColor: Color.Gray,
                      blurStyle: BlurStyle.Regular,
                      showClose:false,
                      enableOutsideInteractive: false, //不允许交互，显示蒙层
                      maskColor:$r('sys.color.ohos_id_blur_style_background_ultra_thick_color'),
                      preferType: SheetType.CENTER,

                      shouldDismiss: ((sheetDismiss: SheetDismiss) => {
                        console.log("bind sheet shouldDismiss")
                        this.isShow[index] = !this.isShow[index]
                        sheetDismiss.dismiss()
                      })
                    })

                  }.onClick(()=>{
                    this.selectPaper = paper
                    this.isShow[index] = !this.isShow[index]
                    console.log("dfds",this.isShow[index] )

                  })
                }, (item: ArxivPaper, _index: number) => item.title)
              }
              .width('90%')
              .columnsGap($r('app.float.grid_column_gap'))
              .rowsGap($r('app.float.grid_row_gap'))
              .columnsTemplate(this.colTemplate)
              .onAreaChange(() => {
                this.colTemplate = new BreakPointType({
                  sm: CommonConstants.SM_COL_TEMPLATE,
                  md: CommonConstants.MD_COL_TEMPLATE,
                  lg: CommonConstants.LG_COL_TEMPLATE,
                  xl: CommonConstants.XL_COL_TEMPLATE
                }).getValue(this.currentBreakpoint);
              })
              .margin({
                left: $r('app.float.grid_margin_left'),
                right: $r('app.float.grid_margin_right')
              })
              .padding({ bottom: 20 })
              .scrollBar(BarState.Off)
            }
          }.width('100%').height('100%').scrollable(ScrollDirection.Vertical)
        }

      }


    }.width('100%').height('100%').padding('5%').alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
  }
}

