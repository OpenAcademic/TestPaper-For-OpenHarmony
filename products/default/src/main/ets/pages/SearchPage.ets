import { ArxivConfig, ArxivType, arxivTypeLabels, downloadPDF, getArxivType, getPapers } from '../api/ArxivApi'
import { promptAction, router, SwipeRefresher } from '@kit.ArkUI'
import { ArxivPaper } from '../entity/ArxivPaper'
import { common, Want, wantConstant } from '@kit.AbilityKit'
import * as CommonConstants from '../constants/CommonConstants';
import { BreakPointType } from '@ohos/common';
import { Paper, paperTime2Str } from '../entity/Paper';
import { BottomTools } from '../widget/BottonTools';
import { store } from '../defaultability/DefaultAbility';
import { fileUri } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor } from '@kit.ArkData';

enum Condition{
  AND,
  OR,
  AND_NOT
}
let condition2Labels = ["与","或","与非"]
function conditionLabel2Condition(string:string) : Condition {

  if (string==="与"){
    return Condition.AND
  } else if (string==="或"){
    return Condition.OR
  } else if (string==="与非"){
    return Condition.AND_NOT
  }
  return Condition.AND


}

function condition2ConditionLabel(string:Condition) : string {

  if (string===Condition.AND){
    return "与"
  } else if (string===Condition.OR){
    return "或"
  } else if (string===Condition.AND_NOT){
    return "与非"
  }
  return "与"


}

class HighCondition{
  key:ArxivType=ArxivType.TITTLE
  condition:Condition=Condition.AND
  value:string=""
  constructor(key:ArxivType,val:string) {
    this.key=key
    this.value=val
  }
}
@Entry
@Component
struct SearchPage {
  @State isHighSearch: boolean = false;
  controller: SearchController = new SearchController()
  @State conditions : HighCondition[] = []
  @State isShow: boolean[] = [];

  @State selectPaper : ArxivPaper | null = null
  @State select_index : number = 0;
  @StorageProp('bottomRectHeight')
  bottomRectHeight: number = 0;
  @StorageProp('topRectHeight')
  topRectHeight: number = 0;
  @State papers : ArxivPaper[] = []
  @State isSearched : boolean = false
  @State isLoading : boolean = false

  @StorageProp('mainBreakpoint') currentBreakpoint: string = CommonConstants.BREAKPOINTS_INITIALIZE_NAME;
  @State colTemplate: string = CommonConstants.INITIALIZE_TEMPLATE;
  private context = getContext() as common.UIAbilityContext;
  aboutToAppear(): void {
    arxivTypeLabels.forEach((value:string,index:number)=>{
      this.conditions.push(new HighCondition(
        getArxivType(index),""
      ))
    })
  }
  async onHighSearch(){
    let arxivConfig: ArxivConfig | null = null
    this.isLoading = true
    this.conditions.forEach((value:HighCondition,index:number)=>{
      if (value.value!=""){
        if (arxivConfig===null){
          arxivConfig = new ArxivConfig(
            value.key,value.value
          )
        }else{
          arxivConfig = arxivConfig as ArxivConfig
          if (value.condition===Condition.AND){
            arxivConfig.and(new ArxivConfig(value.key,value.value))
          } else if (value.condition===Condition.OR){
            arxivConfig.or(new ArxivConfig(value.key,value.value))
          } else if (value.condition===Condition.AND_NOT){
            arxivConfig.andnot(new ArxivConfig(value.key,value.value))
          }

        }
      }
    })
    if (arxivConfig===null){
      promptAction.showToast({
        message:"您尚未输入搜索条件",
        duration:2000
      })
    }else{
      arxivConfig = arxivConfig as ArxivConfig
      let str = arxivConfig.toTiaojianString()
      console.log("paper",str)

      let data = await getPapers(str)
      if (data){
        this.papers = data
        if (data.length===0){
          promptAction.showToast({
            message:"尚未搜到内容",
            duration:2000
          })
        }else{
          for (let i = 0; i < this.papers.length; i++) {
            this.isShow.push(false)
          }
          this.isSearched=true
        }
      }

    }
    this.isLoading = false

  }
  async onCommunSearch(text:string){
    if (!text){
      promptAction.showToast({
        message:"您尚未输入搜索内容",
        duration:2000
      })
    }
    this.isLoading = true
    let arxivConfig: ArxivConfig = new ArxivConfig(ArxivType.ALL,text)
    let str = arxivConfig.toTiaojianString()
    console.log("paper",str)

    let data = await getPapers(str)
    if (data){
      this.papers = data
      if (data.length===0){
        promptAction.showToast({
          message:"尚未搜到内容",
          duration:2000
        })
      }else{
        for (let i = 0; i < this.papers.length; i++) {
          this.isShow.push(false)
        }
        this.isSearched=true
      }
    }
    this.isLoading = false
  }
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
                      this.isShow[this.papers.findIndex(item=>item.id === aid)] = false

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
                  this.isShow[this.papers.findIndex(item=>item.id === this.selectPaper?.id)] = false

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
  build() {
    if (this.isLoading){
      RelativeContainer() {
        Column(){
          SwipeRefresher({
            content:"正在搜索中...",
            isLoading:this.isLoading
          }).width('200vp')
        }.height('100%')
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
      }.height('100%')
      .width('100%').padding({ top: px2vp(this.topRectHeight), bottom: px2vp(this.bottomRectHeight) })

    }else{
      if (!this.isSearched){
        RelativeContainer() {

            Column(){
              Row() {
                Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
                  Flex({
                    direction: FlexDirection.Row,
                    justifyContent: FlexAlign.Center,
                    alignItems: ItemAlign.Center
                  }) {
                    SymbolGlyph($r("sys.symbol.chevron_left"))
                      .fontSize(30)
                      .offset({
                        x: -1,
                        y: 0,
                      })
                  }
                }
                .height(44)
                .width(44)
                .onClick(e => {
                  router.back()
                }).margin({
                  left: $r('app.float.grid_margin_left'),
                  right: $r('app.float.grid_margin_right')
                })
              }
              .width('100%')
              .height('80vp').margin({
                left: $r('app.float.grid_margin_left'),
                right: $r('app.float.grid_margin_right')
              })
              .justifyContent(FlexAlign.Start)
              Scroll(){
              Column(){
                Image($r('app.media.search_logo')).width('400vp')
                if (this.isHighSearch){
                  Column(){
                    List({space: 5}){
                      ForEach(arxivTypeLabels,(item:string, index: number)=> {
                        ListItem(){
                          Row(){
                            Text(item)
                            Row(){
                              Button(condition2ConditionLabel(this.conditions[index].condition))
                                .onClick(() => {
                                  TextPickerDialog.show({ // 建议使用 this.getUIContext().showTextPickerDialog()接口
                                    range: condition2Labels,
                                    selected: condition2Labels.indexOf(condition2ConditionLabel(this.conditions[index].condition)),
                                    disappearTextStyle: { color: Color.Red, font: { size: 15, weight: FontWeight.Lighter }},
                                    textStyle: { color: Color.Black, font: { size: 20, weight: FontWeight.Normal }},
                                    selectedTextStyle: { color: Color.Blue, font: { size: 30, weight: FontWeight.Bolder }},
                                    onAccept: (value: TextPickerResult) => {
                                      // 设置select为按下确定按钮时候的选中项index，这样当弹窗再次弹出时显示选中的是上一次确定的选项
                                      let tempList: HighCondition[] = []
                                      tempList=tempList.concat(this.conditions)
                                      tempList[index].condition = conditionLabel2Condition(
                                        value.value.toString()
                                      );
                                      //然后清空dataList，这是必然会刷新UI
                                      this.conditions = []

                                      this.conditions = tempList
                                      console.log(condition2ConditionLabel(this.conditions[index].condition) + '');
                                      // 点击确定后，被选到的文本数据展示到页面
                                    },
                                    onCancel: () => {
                                      console.info("TextPickerDialog:onCancel()");
                                    },

                                    enableHoverMode: true,
                                    hoverModeArea: HoverModeAreaType.TOP_SCREEN
                                  })
                                })
                              TextInput({
                                placeholder:"请输入高级参数："+item})
                                .maxLines(1).width('40%').onChange((value: string) => {
                                this.conditions[index].value = value;
                              })
                            }

                          }.width('80%').alignItems(VerticalAlign.Center)
                          .justifyContent(FlexAlign.SpaceBetween)
                          .transition( TransitionEffect.OPACITY
                            .animation({
                              duration: 100*(index-1)
                            , curve: Curve.Friction }))
                        }.width('100%')
                      })
                    }
                    .width('100%').margin({
                      top:15,bottom:15
                    })
                    Button('搜索').width('40%').onClick(async ()=>{
                      await this.onHighSearch()
                    })
                  }.width('100%').alignItems(HorizontalAlign.Center)
                  .justifyContent(FlexAlign.Center)


                }
                else{
                  Search({
                    placeholder:"搜索Arxiv论文",
                    controller: this.controller
                  }).width('80%').onSubmit(async e=>{
                    await this.onCommunSearch(e)
                  }).searchButton("搜索").transition( TransitionEffect.OPACITY
                    .animation({ duration: 800, curve: Curve.Friction }))
                }
                Button(this.isHighSearch?"关闭高级搜索":"高级搜索").type(ButtonType.Normal)
                  .buttonStyle(ButtonStyleMode.TEXTUAL)
                  .onClick(e=>{
                    this.getUIContext()?.animateTo({
                      duration: 800,
                      curve: Curve.Friction
                    }, () => {
                      this.isHighSearch=!this.isHighSearch
                    });
                  })
              }.width('100%').alignItems(HorizontalAlign.Center)
              .height('90%').justifyContent(FlexAlign.Center)
              }.height('110%')
              .width('100%')

            }.height('100%')
            .width('100%').alignItems(HorizontalAlign.Center)
            .justifyContent(FlexAlign.SpaceBetween)

        }
        .height('100%')
        .width('100%').padding({ top: px2vp(this.topRectHeight), bottom: px2vp(this.bottomRectHeight) })

      }
      else {
        Stack({ alignContent: Alignment.BottomEnd }) {
          Column() {
            Row() {
              Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
                Flex({
                  direction: FlexDirection.Row,
                  justifyContent: FlexAlign.Center,
                  alignItems: ItemAlign.Center
                }) {
                  SymbolGlyph($r("sys.symbol.chevron_left"))
                    .fontSize(30)
                    .offset({
                      x: -1,
                      y: 0,
                    })
                }
              }
              .height(44)
              .width(44)
              .onClick(e => {
                this.isSearched = false
                this.papers = []
              }).margin({
                left: $r('app.float.grid_margin_left'),
                right: $r('app.float.grid_margin_right')
              })
            }
            .width('100%')
            .height('80vp').margin({
              left: $r('app.float.grid_margin_left'),
              right: $r('app.float.grid_margin_right')
            })
            .justifyContent(FlexAlign.Start)

            Column() {
              WaterFlow() {

                ForEach(this.papers, (paper: ArxivPaper, index) => {

                  FlowItem() {
                    Column() {
                      Row() {
                        Text(paper.journal)
                          .margin(5)
                          .fontSize(15)
                          .textAlign(TextAlign.Start)
                          .fontStyle(FontStyle.Italic)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .fontColor($r('sys.color.ohos_id_color_text_primary'))

                      }.width('100%').justifyContent(FlexAlign.Start)

                      Text(paper.title)
                        .margin(5)
                        .wordBreak(WordBreak.BREAK_WORD)
                        .fontWeight(FontWeight.Bold)
                        .fontSize(24)
                        .textAlign(TextAlign.Start)
                        .width('100%')
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .fontColor($r('sys.color.ohos_id_color_text_primary'))
                      Row() {

                        Text(paperTime2Str(paper.updated))
                          .margin(5)
                          .fontSize(15)
                          .textAlign(TextAlign.Start)
                          .fontStyle(FontStyle.Italic)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
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
                      showClose: false,
                      enableOutsideInteractive: false, //不允许交互，显示蒙层
                      maskColor: $r('sys.color.ohos_id_blur_style_background_ultra_thick_color'),
                      preferType: SheetType.CENTER,

                      shouldDismiss: ((sheetDismiss: SheetDismiss) => {
                        console.log("bind sheet shouldDismiss")
                        this.isShow[index] = !this.isShow[index]
                        sheetDismiss.dismiss()
                      })
                    })
                  }.onClick(() => {
                    this.select_index = index
                    this.selectPaper = this.papers[index]
                    this.isShow[index] = !this.isShow[index]
                    console.log("dfds", this.isShow[index])

                  })

                }, (item: ArxivPaper, _index: number) => item.id?.toString())

              }
              .height('120%')
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

            }.width('100%').height('120%')

          }.width('100%').height('100%').align(Alignment.Center)

        }
        .width('100%').height('100%').padding({ top: px2vp(this.topRectHeight), bottom: px2vp(this.bottomRectHeight) })

      }
    }

  }
}