import { promptAction, router, SelectOptions, SwipeRefresher } from '@kit.ArkUI';
import { BreakPointType } from '@ohos/common';
import { ArxivConfigBuilder, ArxivType, downloadPDF, getPapers } from '../api/ArxivApi';
import * as CommonConstants from '../constants/CommonConstants';
import { store } from '../defaultability/DefaultAbility';
import { ArxivPaper } from '../entity/ArxivPaper';
import {  Paper, paperTime2Str } from '../entity/Paper';
import { BottomTools } from '../widget/BottonTools';
import { pdfService } from '@kit.PDFKit';
import { common, Want, wantConstant } from '@kit.AbilityKit';
import { uniformTypeDescriptor } from '@kit.ArkData';
import { systemShare } from '@kit.ShareKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileUri } from '@kit.CoreFileKit';

/**
 * Grid component.
 */

@Component
@Preview
export struct GridComponent {
  @State isShow: boolean[] = [];
  @State select_index : number = 0;
  nextPage : ()=>void = ()=>{}

  @State show_search : boolean = false;
  @StorageProp('mainBreakpoint') currentBreakpoint: string = CommonConstants.BREAKPOINTS_INITIALIZE_NAME;
  @State colTemplate: string = CommonConstants.INITIALIZE_TEMPLATE;
  private context = getContext() as common.UIAbilityContext;

  @State data: Paper[] = [];
  @State is_begain_srarching : boolean = true
  @State is_loading : boolean = false
  @State page:number = 1
  @State info?: ArxivPaper|null = null
  @State isloading_more : boolean= false
  @State isloading_reflash : boolean= false

  async aboutToReuse() {


  }

  async aboutToAppear() {
    await this.onListShow();
    switch (this.currentBreakpoint) {
      case CommonConstants.BREAKPOINTS_SM_NAME:
        this.colTemplate = CommonConstants.SM_COL_TEMPLATE;
        break;
      case CommonConstants.BREAKPOINTS_MD_NAME:
        this.colTemplate = CommonConstants.MD_COL_TEMPLATE;
        break;
      case CommonConstants.BREAKPOINTS_LG_NAME:
        this.colTemplate = CommonConstants.LG_COL_TEMPLATE;
        break;
      case CommonConstants.BREAKPOINTS_XL_NAME:
        this.colTemplate = CommonConstants.XL_COL_TEMPLATE;
        break;
      default:
        this.colTemplate = CommonConstants.SM_COL_TEMPLATE;
        break;
    }
  }
  async onListShow() {
    this.data = []
    if (store){
      this.data=this.data.concat(await Paper.get_papers_by_page(store,this.page))

    }
  }
  @Builder
  searcher(){
    Column(){
      if (this.is_begain_srarching){
        Text("添加文章")
          .maxLines(1)
          .margin({bottom:20})
          .fontSize(40)
          .textAlign(TextAlign.Center)
          .fontWeight(FontWeight.Bolder)
          .width('90%')
          .textOverflow({overflow:TextOverflow.Ellipsis})
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
        Row(){
          Search({placeholder:"请输入arxiv id（目前仅支持arxiv id）"}).width('100%').onSubmit(async e=>{
            if (!e){
              promptAction.showToast({
                message:"您还没有输入哦",
                duration:2000
              })
              return
            }
            console.info("id",ArxivConfigBuilder(ArxivType.ID,e).toTiaojianString())
            this.is_loading = true
            const res = await getPapers(ArxivConfigBuilder(ArxivType.ID,e).toTiaojianString())
            if (res && res.length>0){
              this.info = res[0]
              this.is_begain_srarching = false
              this.is_loading = false
            }
            else{
              promptAction.showToast({
                message:"尚未找到",
                duration:2000
              })
              this.show_search = false
              this.is_loading = false
            }
          }).searchButton("搜索")
        }.width('90%')
        if (this.is_loading){
          LoadingProgress().size({width:50,height:50})
        }
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

                }.width('100%').alignItems(HorizontalAlign.Start)
              }.width('100%')
              .height('85%')

              BottomTools({
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
                        this.show_search = false
                        await this.onListShow()

                      }

                    }

                  }
                },
                onRead:async ()=> {
                  let context = this.context
                  if (this.info?.licenses){
                    let uri =await downloadPDF(this.info?.licenses, this.context, this.info?.id)
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
                    this.show_search = false
                    await this.onListShow()

                  }

                }
              }).width('95%').margin(5)




            }.width('100%')
            .height('100%').alignItems(HorizontalAlign.Start).justifyContent(FlexAlign.SpaceBetween)

          }.alignContent(Alignment.TopStart).margin(20)
          .width('95%')
          .height('100%')
        }

      }




    }.width('100%').height('100%').padding('5%').alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)

  }
  @Builder
  myBuilder() {
    Stack(){
      Column(){
        Scroll(){
          Column() {
            Text(this.data[this.select_index].arxiv_id)
              .margin(5)
              .fontSize(15)
              .textAlign(TextAlign.Start)
              .fontStyle(FontStyle.Italic)
              .width('90%')
              .textOverflow({overflow:TextOverflow.Ellipsis})
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
            Text(this.data[this.select_index].title)
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
            Text(this.data[this.select_index].author)
              .margin(5)
              .fontSize(15)
              .textAlign(TextAlign.Start)
              .fontStyle(FontStyle.Italic)
              .width('90%')
              .textOverflow({overflow:TextOverflow.Ellipsis})
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
            Text(this.data[this.select_index].abstract)
              .margin(5).wordBreak(WordBreak.BREAK_ALL)
              .fontSize(15)
              .textAlign(TextAlign.Start)
              .width('90%')
              .textOverflow({overflow:TextOverflow.Ellipsis})
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
            Text("DOI:"+this.data[this.select_index].doi)
              .margin(5)
              .fontSize(15)
              .textAlign(TextAlign.Start)
              .fontStyle(FontStyle.Italic)
              .width('90%')
              .textOverflow({overflow:TextOverflow.Ellipsis})
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
          }.width('100%').alignItems(HorizontalAlign.Start)
        }.width('100%')
        .height('85%')

        BottomTools({
          aid:this.data[this.select_index].arxiv_id,
          onDelete:async ()=>{
            if (store){
              console.info("delete")
              let aid = this.data[this.select_index].arxiv_id
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
                  await this.onListShow()
                  this.show_search = false
                  this.select_index = 0

                }

              }

            }
          },
          onRead:async ()=> {
            let context = this.context
            let uri =await downloadPDF(this.data[this.select_index].keywords, this.context, this.data[this.select_index].arxiv_id)
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

          },
          onShare : ()=>{
            let shareData: systemShare.SharedData = new systemShare.SharedData({
              utd: uniformTypeDescriptor.UniformDataType.TEXT,
              content: this.data[this.select_index].title+"\n"+this.data[this.select_index].abstract,
              title: this.data[this.select_index].title,
              description:  this.data[this.select_index].title+"\n"+this.data[this.select_index].abstract,
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
          }
        }).width('95%').margin(5)
      }.width('100%')
      .height('100%').alignItems(HorizontalAlign.Start).justifyContent(FlexAlign.SpaceBetween)

    }.alignContent(Alignment.TopStart).margin(20)
    .width('95%')
    .height('100%')


  }
  @Builder
  flash(){
    Row(){
      LoadingProgress().size({
        width:60,height:60
      })
    }.width('100%').alignItems(VerticalAlign.Center).justifyContent(FlexAlign.Center)
  }
  build() {
    Stack({ alignContent: Alignment.BottomEnd }){
      Column() {

        if (this.data.length===0){
          Column(){
            Image($r('app.media.empty')).size({width:250,height:250})
            Text("内容为空，去添加一个吧")
              .margin(5)
              .fontSize(24)
              .textAlign(TextAlign.Center)
              .width('100%')
              .textOverflow({overflow:TextOverflow.Ellipsis})
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
            Button("添加").width(150).onClick(e=>{
              this.show_search = !this.show_search
            }).bindSheet(this.show_search, this.searcher(), {
              detents: [SheetSize.LARGE],
              backgroundColor: Color.Gray,

              blurStyle: BlurStyle.Regular,
              showClose:true,
              enableOutsideInteractive: false, //不允许交互，显示蒙层

              maskColor:$r('sys.color.ohos_id_blur_style_background_ultra_thick_color'),
              preferType: SheetType.CENTER,


              shouldDismiss: ((sheetDismiss: SheetDismiss) => {
                console.log("bind sheet shouldDismiss")
                this.show_search = !this.show_search
                this.info = null
                this.is_begain_srarching = true
                sheetDismiss.dismiss()
              })
            })

          }.width('100%').height('100%').alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
        }
        else{
          Row() {
            Image($r('app.media.jia')).size({width:30,height:30}).margin({ right: $r('app.float.arrow_margin_left') })
              .onClick(e=>{
                this.show_search = !this.show_search
                this.is_begain_srarching = true

              })
              .bindSheet(this.show_search, this.searcher(), {
                detents: [SheetSize.LARGE],
                backgroundColor: Color.Gray,

                blurStyle: BlurStyle.Regular,
                showClose:true,
                enableOutsideInteractive: false, //不允许交互，显示蒙层

                maskColor:$r('sys.color.ohos_id_blur_style_background_ultra_thick_color'),
                preferType: SheetType.CENTER,


                shouldDismiss: ((sheetDismiss: SheetDismiss) => {
                  console.log("bind sheet shouldDismiss")
                  this.show_search = !this.show_search
                  this.info = null
                  this.is_begain_srarching = true
                  sheetDismiss.dismiss()
                })
              })

          }
          .width(CommonConstants.ROW_WIDTH)
          .height('80vp')
          .justifyContent(FlexAlign.End)

          Refresh({refreshing:this.isloading_reflash}){
            Column(){
              WaterFlow(

              ) {

                ForEach(this.data, (paper:Paper,index) => {

                  FlowItem() {
                    Column() {
                      Row(){
                        Text(paper.jourly)
                          .margin(5)
                          .fontSize(15)
                          .textAlign(TextAlign.Start)
                          .fontStyle(FontStyle.Italic)
                          .textOverflow({overflow:TextOverflow.Ellipsis})
                          .fontColor($r('sys.color.ohos_id_color_text_primary'))

                      }.width('100%').justifyContent(FlexAlign.Start)
                      Text(paper.title)
                        .margin(5).wordBreak(WordBreak.BREAK_WORD).fontWeight(FontWeight.Bold)
                        .fontSize(24)
                        .textAlign(TextAlign.Start)
                        .width('100%')
                        .textOverflow({overflow:TextOverflow.Ellipsis})
                        .fontColor($r('sys.color.ohos_id_color_text_primary'))
                      Row(){

                        Text(paperTime2Str(paper.publishTime))
                          .margin(5)
                          .fontSize(15)
                          .textAlign(TextAlign.Start)
                          .fontStyle(FontStyle.Italic)
                          .textOverflow({overflow:TextOverflow.Ellipsis})
                          .fontColor($r('sys.color.ohos_id_color_text_primary'))
                      }.width('100%').justifyContent(FlexAlign.End)

                    }
                    .backgroundColor(
                      $r('sys.color.ohos_id_blur_style_background_thin_color')
                    )
                    .padding(15)
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
                    this.select_index = index
                    this.isShow[index] = !this.isShow[index]
                    console.log("dfds",this.isShow[index] )

                  })


                }, (item: Paper, _index: number) => item.arxiv_id?.toString())

              }.height('100%')
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


            }.width('100%').height('100%')

          } .width('100%').height('130%') .onRefreshing(async ()=>{
            this.page==1
            this.isloading_reflash=true
            if (store){
              this.data = []
              let new_data=await Paper.get_papers_by_page(store,this.page)
              this.data = this.data.concat(new_data)
              this.isloading_reflash=false
              promptAction.showToast({
                duration:2000,
                message:"已刷新"
              })

            }
          })



        }

      }.width('100%').height('100%').align(Alignment.Center)
      if (this.data.length>0){
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Image($r('app.media.next')).width('40vp').height('40vp')
        }.size({
          width:'80vp',height:'80vp'
        }).onClick(async ()=>{
          this.page+=1
          this.isloading_more=true
          if (store){
            let new_data=await Paper.get_papers_by_page(store,this.page)

            if (new_data.length===0){
              promptAction.showToast({
                duration:2000,
                message:"已经没有更多数据了"
              })
              this.page-=1
            }else{
              this.data = this.data.concat(new_data)
            }
            this.isloading_more=false

          }
        }).margin("20vp")
      }
    }.width('100%').height('100%')

  }
}