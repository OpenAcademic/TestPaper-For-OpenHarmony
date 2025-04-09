import { pdfService, PdfView, pdfViewManager } from '@kit.PDFKit';
import { common } from '@kit.AbilityKit';
import {
  DividerModifier,
  font,
  LengthMetrics,
  OperationType, router, SubHeader, SymbolGlyphModifier, ToolBar,
  ToolBarModifier,
  ToolBarOptions,
  UIContext } from '@kit.ArkUI';
import { fileIo } from '@kit.CoreFileKit';
import * as CommonConstants from '../constants/CommonConstants';
import { BreakPointType } from '@ohos/common';
import { SideBar } from '../widget/SideBar';
import { getTranslateRes } from '../api/TranslateApi';
import { PaperNote } from '../entity/PaperNote';
import { store } from '../defaultability/DefaultAbility';
import { relationalStore } from '@kit.ArkData';


function  getLabelByType(type: pdfViewManager.SupportedAnnotationType): string {
  if(type === pdfViewManager.SupportedAnnotationType.UNKNOWN){
    return '选择'
  } else if(type === pdfViewManager.SupportedAnnotationType.FREE_TEXT){
    return '自由文本'
  }else if(type === pdfViewManager.SupportedAnnotationType.LINE){
    return '线条'
  }else if(type === pdfViewManager.SupportedAnnotationType.SQUARE){
    return '方形'
  }else if(type === pdfViewManager.SupportedAnnotationType.OVAL){
    return '圆形'
  }else if(type === pdfViewManager.SupportedAnnotationType.HIGHLIGHT){
    return '高亮'
  }else if(type === pdfViewManager.SupportedAnnotationType.POLYGON){
    return '多边形'
  }else if(type === pdfViewManager.SupportedAnnotationType.STRIKETHROUGH){
    return '删除线'
  }else if(type === pdfViewManager.SupportedAnnotationType.UNDERLINE){
    return '下划线'
  }

  return  '未知';
}
function  getLabelByIconAndClick(
  type: pdfViewManager.SupportedAnnotationType,
  click:boolean
): Resource {
  if(type === pdfViewManager.SupportedAnnotationType.UNKNOWN){
    return click?$r('app.media.dianji'):$r('app.media.dianji_un')
  } else if(type === pdfViewManager.SupportedAnnotationType.FREE_TEXT){
    return click?$r('app.media.zitiyanse'):$r('app.media.zitiyanse_un')
  }else if(type === pdfViewManager.SupportedAnnotationType.LINE){
    return click?$r('app.media.huaxian'):$r('app.media.huaxian_un')
  }else if(type === pdfViewManager.SupportedAnnotationType.SQUARE){
    return click?$r('app.media.fangxingweixuanzhong'):$r('app.media.fangxingweixuanzhong_un')
  }else if(type === pdfViewManager.SupportedAnnotationType.OVAL){
    return click?$r('app.media.ellipse'):$r('app.media.ellipse_un')
  }else if(type === pdfViewManager.SupportedAnnotationType.HIGHLIGHT){
    return click?$r('app.media.highlight'):$r('app.media.highlight_un')
  }else if(type === pdfViewManager.SupportedAnnotationType.POLYGON){
    return click?$r('app.media.polygon'):$r('app.media.polygon_un')
  }else if(type === pdfViewManager.SupportedAnnotationType.STRIKETHROUGH){
    return click?$r('app.media.strikethrough'):$r('app.media.strikethrough_un')
  }else if(type === pdfViewManager.SupportedAnnotationType.UNDERLINE){
    return click?$r('app.media.xiahuaxian'):$r('app.media.xiahuaxian_un')
  }

  return  $r('app.media.xiahuaxian');
}


export class PDFConfig{
  url:string
  aid:string

  constructor(id:string,aid:string) {
    this.url = id
    this.aid = aid
  }
}
// 自定义颜色按钮组件
@Component
struct ColorButton {
  @Prop color: string
  @Prop isSelected: boolean = false
  onClicked:  () => void = () => {};

  build() {
    Button({ type: ButtonType.Circle }) {
      // 空内容，使用背景色作为按钮颜色
    }
    .size({ width: 24, height: 24 })
    .backgroundColor(this.color)
    .border({
      width: this.isSelected ? 2 : 0,
      color: '#000000',
      style: BorderStyle.Solid
    })
    .onClick(() => this.onClicked())
  }
}

// 自定义工具按钮组件
@Component
struct ToolButton {
  @Prop icon: Resource
  @Prop isActive: boolean = false
  onClicked: () => void = () => {};

  build() {
    Button({ type: ButtonType.Circle, stateEffect: true }) {
      Image(this.icon)
        .size({ width: 24, height: 24 })
    }
    .size({ width: 40, height: 40 })
    .backgroundColor(this.isActive ? '#E0E0E0' : '#F5F5F5')
    .onClick(() => this.onClicked())
  }
}


class ColorPickers{
  color: string
  value: number
  constructor(color: string,value: number ) {
    this.color = color
    this.value = value
  }
}
@Entry
@Component
struct PDFReaderPage {
  @State showAnnotationList: boolean = false; // 新增：控制批注列表的显示
  @State message: string = 'Hello World';
  
  // 注释颜色相关状态
  @State selectedColorIndex: number = 0
  @State annotationColors: ColorPickers[] = [
    new ColorPickers('#FFFF00',0xAAFFFF00),
    new ColorPickers('#FF9900',0xAAFF9900),
    new ColorPickers('#FF0000',0xAAFF0000),
    new ColorPickers('#00FF00',0xAA00FF00),
    new ColorPickers('#0000FF',0xAA0000FF),
  ]
  @State currentAnnotationColor: number = 0xAAFFFF00 // 默认黄色
  private pdfDocument: pdfService.PdfDocument = new pdfService.PdfDocument();
  private context = getContext() as common.UIAbilityContext;
  @State filePath : string= "";
  @State aid : string = ""

  @State saveEnable: boolean = false;
  private controller: pdfViewManager.PdfController = new pdfViewManager.PdfController();
  @StorageProp('mainBreakpoint') currentBreakpoint: string = CommonConstants.BREAKPOINTS_INITIALIZE_NAME;
  @State colTemplate: pdfService.PageLayout = pdfService.PageLayout.LAYOUT_SINGLE;
  @State currentAnnotationType: pdfViewManager.SupportedAnnotationType = pdfViewManager.SupportedAnnotationType.UNKNOWN;


  @State scaleValue: number = 1
  @State pinchValue: number = 1
  @State pinchX: number = 0
  @State pinchY: number = 0

  @State selectWords : pdfViewManager.TextSelectedParam = new pdfViewManager.TextSelectedParam();
  @State selectShow : boolean = false;
  @State selectPzShow : boolean = false;

  @State translateRes : string | null= ""

  @State tool_bars : ToolbarItem[] =  []
  @State paper_notes : PaperNote[] = []
  @State select_status : number = 0
  @State select_annotation_id: number = -1
  @State select_annotation_page_id: number = -1

  private toolBarModifier: ToolBarModifier =
    new ToolBarModifier().height(LengthMetrics.vp(52)).backgroundColor(Color.Transparent).stateEffect(false);
  @State dividerModifier: DividerModifier = new DividerModifier().height(0);


  async aboutToAppear() {
    const params = router.getParams() as PDFConfig;
    this.filePath = params.url || '';
    this.aid = params.aid as string;

    switch (this.currentBreakpoint) {
      case CommonConstants.BREAKPOINTS_SM_NAME:
        this.colTemplate =pdfService.PageLayout.LAYOUT_SINGLE;
        break;
      case CommonConstants.BREAKPOINTS_MD_NAME:
        this.colTemplate = pdfService.PageLayout.LAYOUT_SINGLE;
        break;
      case CommonConstants.BREAKPOINTS_LG_NAME:
        this.colTemplate = pdfService.PageLayout.LAYOUT_DOUBLE;
        break;
      case CommonConstants.BREAKPOINTS_XL_NAME:
        this.colTemplate =  pdfService.PageLayout.LAYOUT_DOUBLE;
        break;
      default:
        this.colTemplate = pdfService.PageLayout.LAYOUT_SINGLE;
        break;
    }

    let res = fileIo.accessSync(this.filePath);
    if(!res) {
      // 确保在工程目录src/main/resources/rawfile里有input.pdf文档
      let content: Uint8Array = this.context.resourceManager.getRawFileContentSync('rawfile/input.pdf');
      let fdSand =
        fileIo.openSync(this.filePath, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      fileIo.writeSync(fdSand.fd, content.buffer);
      fileIo.closeSync(fdSand.fd);
    }
    this.pdfDocument.loadDocument(this.filePath);
    (async () => {
      this.controller.registerPageCountChangedListener((pageCount: number) => {
      });
      // 注意：这里刚加载文档，请不要在这里立即设置PDF文档的预览方法。
      let loadResult1: pdfService.ParseResult = await this.controller.loadDocument(this.filePath);
      this.controller.setPageLayout(this.colTemplate);
      this.controller.setPageFit(pdfService.PageFit.FIT_NONE);
      this.controller.registerTextSelectedListener(async (text: pdfViewManager.TextSelectedParam) => {
        this.selectShow = false
        console.info('text:' + text.text);
        this.selectWords = text;
        if (text.text.toString()!==""){
          await this.addInfos()

        }
      });
      this.controller.registerSelectedRectsChangedListener((select:pdfViewManager.SelectedRects[])=>{

      })

      this.controller.registerAnnotationSelectedListener((select:pdfViewManager.SelectedAnnotation)=>{
        if (select.annotationIndex){
          console.log("annotationIndex")
          this.selectShow = !this.selectShow
          this.select_annotation_id = select.annotationIndex
          this.select_annotation_page_id = select.pageIndex
        }
      })
      let p : pdfViewManager.SupportedAnnotationType[] = [
        pdfViewManager.SupportedAnnotationType.UNKNOWN,
        pdfViewManager.SupportedAnnotationType.FREE_TEXT,
        pdfViewManager.SupportedAnnotationType.HIGHLIGHT,
        pdfViewManager.SupportedAnnotationType.STRIKETHROUGH,
        pdfViewManager.SupportedAnnotationType.UNDERLINE,

        pdfViewManager.SupportedAnnotationType.LINE,
        pdfViewManager.SupportedAnnotationType.SQUARE,
        pdfViewManager.SupportedAnnotationType.OVAL,
        pdfViewManager.SupportedAnnotationType.POLYGON,

      ]

      for (let i = 0 ; i<p.length;i++) {
        this.tool_bars.push({
          icon: getLabelByIconAndClick(p[i], false),
          value: getLabelByType(p[i]),
          action: () => {
            this.controller.enableAnnotation(p[i], 0xAAEEEEEE);
            this.select_status = i
          }
        } as ToolbarItem)

        this.paper_notes = await PaperNote.getPaperNotesByAid(store as  relationalStore.RdbStore,this.aid)


      }



    })()






  }

  async addText(text:string){
    let len : number = this.selectWords.pdfRect.length - 1
    let page: pdfService.PdfPage = this.pdfDocument.getPage(this.selectWords.pdfRect[len].pageIndex);
    let textStyle: pdfService.TextStyle = new pdfService.TextStyle;
    let fontList: Array<string> = font.getSystemFontList();
    let fontInfo = new pdfService.FontInfo();
    if (fontList.length > 0) {
      fontInfo.fontPath = font.getFontByName(fontList[0]).path;
    } else {
      // 确保字体路径存在
      // fontInfo.fontPath = '/system/fonts/HarmonyOS_Sans.ttf';
    }
    textStyle.fontInfo = fontInfo;
    textStyle.textSize = 20;
    page.addTextObject(text, 0, 0, textStyle); //添加示例文字
  }
  async addInfos(){
    console.info('addInfo:'+this.selectWords.pdfRect)

    this.controller.addMarkupAnnotation(
      pdfViewManager.SupportedAnnotationType.HIGHLIGHT,
      this.selectWords.pdfRect,
      this.currentAnnotationColor
    )


  }
  aboutToDisappear() {
    this.controller.saveDocument(this.filePath)

  }
  @Builder
  textShow(){

    Column(){
      Scroll(){
        Column(){
          Text(this.selectWords.text).fontSize(16)
            .width('100%').wordBreak(WordBreak.BREAK_WORD).textAlign(TextAlign.Start)
        }.alignItems(HorizontalAlign.Start).justifyContent(FlexAlign.Start)
      }.scrollable(ScrollDirection.Vertical).width('100%').height('40%').scrollBar(BarState.Auto).margin(20)
      Row(){
        Button("翻译").onClick(async e =>  {
          console.log("res", e)

          console.log("res", this.selectWords.text)
          const res = await getTranslateRes(
            this.selectWords.text,
            "en",
            "zh"
          )
          console.log("res",res)
          this.translateRes = res

        }).margin(10)
        Button("添加").onClick(async e =>  {
          console.log("res", e)

          console.log("res", this.selectWords.text)
          if (store){
            let mStore = store as  relationalStore.RdbStore
            await this.addInfos()
            let lists = this.aid.toString().split("/")

            const res =  PaperNote.insert_paper(
              mStore,
              new PaperNote(
                0,
                lists[lists.length-1],
                this.select_annotation_id,
                this.select_annotation_page_id,
                this.selectWords.text.replace("\n",""),
                this.translateRes?this.translateRes.replace("\n",""):"",
                "",

              )
            )
            await this.addText(this.translateRes as string)
            this.selectWords.text = ""
            this.translateRes = null

          }


        }).margin(10)
      }.width('100%').alignItems(VerticalAlign.Center).height('10%').justifyContent(FlexAlign.End)
      if (this.translateRes){
        Scroll(){
          Column(){
            Text(this.translateRes).fontSize(16)
              .width('100%').wordBreak(WordBreak.BREAK_WORD).textAlign(TextAlign.Start)
          }.alignItems(HorizontalAlign.Start).justifyContent(FlexAlign.Start)
        }.scrollable(ScrollDirection.Vertical).width('100%').height('40%').scrollBar(BarState.Auto).margin(20)

      }
    }.padding('5%').alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
  }

  @Builder
  AnnotationListPanel() {
    Panel(this.showAnnotationList) {
      Column() {
        Text("批注列表").fontSize(20).fontWeight(FontWeight.Bold).margin({ bottom: 16 })
        List() {
          ForEach(this.paper_notes, (note : PaperNote, index) => {
            ListItem() {
              Row() {
                Column() {
                  Text(note.select_info).fontSize(16).textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(note.trans_res).fontSize(14).opacity(0.6).textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                
                Button("删除")
                  .onClick(() => this.deletePaperNote(note.id))
              }
              .width('100%')
              .padding(8)
              .backgroundColor($r('sys.color.comp_background_list_card'))
              .borderRadius(8)
              .margin({ bottom: 8 })
            }
            .onClick(() => this.navigateToPaperNote(note))
          })
        }
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .padding(16)
    }
    .type(PanelType.Foldable)
    .mode(PanelMode.Half)
    .dragBar(true)
    .halfHeight(400)
  }

  private async deletePaperNote(id: number) {
    if (store) {
      let mStore = store as relationalStore.RdbStore;
      await PaperNote.delete_paper(mStore, id);
      // 重新加载批注列表
      this.paper_notes = await PaperNote.getPaperNotesByAid(mStore, this.aid);
    }
  }

  private navigateToPaperNote(note: PaperNote) {
    // 这里可以实现跳转到对应批注的逻辑
    // 例如，可以跳转到PDF的特定页面或位置
    console.info('Navigate to paper note:', note);
    // TODO: 实现跳转逻辑
  }

  @Builder
  RightToolBar() {
    Scroll() {
      Column({ space: 12 }) {

        // 颜色选择器
        Column() {
          Text("颜色")
            .fontSize(12)
            .fontColor('#666666')
            .margin({ bottom: 4 }).width('100%').textAlign(TextAlign.Center)

          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
            ForEach(this.annotationColors, (item: ColorPickers, index) => {
              ColorButton({
                color: item.color,
                isSelected: index === this.selectedColorIndex,
                onClicked: () => {
                  this.selectedColorIndex = index
                  this.currentAnnotationColor = item.value
                  // 如果当前有选中的注释工具，重新启用它以应用新颜色
                  if (this.select_status >= 0) {
                    this.controller.enableAnnotation(this.getAnnotationTypeByIndex(this.select_status),
                      this.currentAnnotationColor)
                  }
                }
              })
                .margin(2)
            })
          }
          .width('100%')
        }
        .width('100%')
        .padding(8)
        .borderRadius(12)
        .backgroundColor($r('sys.color.comp_background_list_card'))
        .margin({ bottom: 8 }).alignItems(HorizontalAlign.Center)

        // 注释工具组
        Column({ space: 8 }) {
          ForEach(this.tool_bars, (item: ToolbarItem, index) => {
            ToolButton({
              icon: getLabelByIconAndClick(this.getAnnotationTypeByIndex(index), index === this.select_status),
              isActive: index === this.select_status,
              onClicked: () => {
                this.controller.enableAnnotation(this.getAnnotationTypeByIndex(index), this.currentAnnotationColor)
                this.select_status = index
              }
            })
          })
        }
        .padding(8)
        .borderRadius(12)
        .backgroundColor($r('sys.color.comp_background_list_card'))

        // 功能按钮组
        Column({ space: 8 }) {
          // 页面布局切换按钮
          ToolButton({
            icon: this.colTemplate === pdfService.PageLayout.LAYOUT_DOUBLE ?
            $r('app.media.singlepage') : $r('app.media.doublepage'),
            onClicked: () => {
              this.colTemplate = this.colTemplate === pdfService.PageLayout.LAYOUT_DOUBLE ?
              pdfService.PageLayout.LAYOUT_SINGLE : pdfService.PageLayout.LAYOUT_DOUBLE
              this.controller.setPageLayout(this.colTemplate)
            }
          })

          // 侧边栏按钮
          ToolButton({
            icon: $r('app.media.sidebar'),
            onClicked: () => {
              this.selectPzShow = false
              if (this.selectWords.text.toString() !== "text:") {
                this.selectShow = !this.selectShow
              }
            }
          })

          // 批注按钮
          ToolButton({
            icon: $r('app.media.pz'),
            onClicked: () => {
              this.selectShow = false
              this.showAnnotationList = !this.showAnnotationList
            }
          })
        }
        .padding(8)
        .borderRadius(12)
        .backgroundColor($r('sys.color.comp_background_list_card'))

      }
      .width('100%')
      .height('100%').padding({
        top: '12vp',
        bottom: '12vp',
        left: '8vp',
        right: '8vp'
      }).alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Start)
      .bindSheet(this.selectShow, this.textShow(), {
        detents: [SheetSize.FIT_CONTENT],
        backgroundColor: Color.Gray,
        blurStyle: BlurStyle.Regular,
        showClose: true,
        enableOutsideInteractive: false,
        maskColor: $r('sys.color.ohos_id_blur_style_background_ultra_thick_color'),
        preferType: SheetType.CENTER,
        shouldDismiss: ((sheetDismiss: SheetDismiss) => {
          this.selectShow = !this.selectShow
          this.translateRes = null
          sheetDismiss.dismiss()
        })
      })
    }.width('72vp').margin({
      top: '0vp',
      bottom: '0vp',
      left: '0vp',
      right: '8vp'
    })
    .height('120%').scrollable(ScrollDirection.Vertical).scrollBar(BarState.Auto).backgroundColor(Color.Transparent)

  }

  private getAnnotationTypeByIndex(index: number): pdfViewManager.SupportedAnnotationType {
    const types = [
      pdfViewManager.SupportedAnnotationType.UNKNOWN,
      pdfViewManager.SupportedAnnotationType.FREE_TEXT,
      pdfViewManager.SupportedAnnotationType.HIGHLIGHT,
      pdfViewManager.SupportedAnnotationType.STRIKETHROUGH,
      pdfViewManager.SupportedAnnotationType.UNDERLINE,
      pdfViewManager.SupportedAnnotationType.LINE,
      pdfViewManager.SupportedAnnotationType.SQUARE,
      pdfViewManager.SupportedAnnotationType.OVAL,
      pdfViewManager.SupportedAnnotationType.POLYGON,
    ]
    return types[index] || pdfViewManager.SupportedAnnotationType.UNKNOWN
  }

  build() {
    Stack() {
    Row(){
      Row() {
        // PDF显示区域
        PdfView({
          controller: this.controller,
          pageFit: pdfService.PageFit.FIT_NONE,
          isContinuous: true,
          pageLayout: this.colTemplate,
          showScroll: true
        })
          .id('pdfview_app_view')
          .width('100%')
          .height('100%')
          .backgroundColor('#FFFFFF')
      }
      .width('calc(100% - 72vp)')
      .height('100%')
      .gesture(
        PinchGesture({ fingers: 3 })
          .onActionStart((event: GestureEvent) => {
            console.info('Pinch start')
          })
          .onActionUpdate((event: GestureEvent) => {
            if (event) {
              this.scaleValue = this.pinchValue * event.scale
              this.pinchX = event.pinchCenterX
              this.pinchY = event.pinchCenterY
            }
          })
          .onActionEnd((event: GestureEvent) => {
            this.pinchValue = this.scaleValue
            console.info('Pinch end' + this.pinchValue)
            this.controller.setPageZoom(this.pinchValue)
          })
      )



      // 右侧工具栏
      this.RightToolBar()
    }
      this.AnnotationListPanel()



    }
    .width('100%')
    .height('100%')
    .onAreaChange((event) => {
      
      this.colTemplate = new BreakPointType<pdfService.PageLayout>({
        sm: pdfService.PageLayout.LAYOUT_SINGLE,
        md: pdfService.PageLayout.LAYOUT_SINGLE,
        lg: pdfService.PageLayout.LAYOUT_DOUBLE,
        xl: pdfService.PageLayout.LAYOUT_DOUBLE
      }).getValue(this.currentBreakpoint)
      switch (this.currentBreakpoint) {
        case CommonConstants.BREAKPOINTS_SM_NAME:
          this.colTemplate =pdfService.PageLayout.LAYOUT_SINGLE;
          break;
        case CommonConstants.BREAKPOINTS_MD_NAME:
          this.colTemplate = pdfService.PageLayout.LAYOUT_SINGLE;
          break;
        case CommonConstants.BREAKPOINTS_LG_NAME:
          this.colTemplate = pdfService.PageLayout.LAYOUT_DOUBLE;
          break;
        case CommonConstants.BREAKPOINTS_XL_NAME:
          this.colTemplate =  pdfService.PageLayout.LAYOUT_DOUBLE;
          break;
        default:
          this.colTemplate = pdfService.PageLayout.LAYOUT_SINGLE;
          break;
      }
    })


  }
}


