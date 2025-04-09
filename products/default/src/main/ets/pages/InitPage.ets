import { loginComponentManager } from '@kit.AccountKit';
import { it } from '@ohos/hypium';
import { dataPreferences } from '../defaultability/DefaultAbility';
import { router } from '@kit.ArkUI';
import { faceDetector } from '@kit.CoreVisionKit';
import { UserInfo } from '../view/MinePage';
import { webview } from '@kit.ArkWeb';

@Entry
@Component
struct InitPage {
  @State message: string = 'Hello World';
  @State isShow : boolean = true
  @State isShowXieyi : boolean = false
  @State isUA:boolean = false
  @State isShowInfoCheck : boolean = false
  @State user_copy:UserInfo|null=null
  @State pa:string = "ysxy.html"
  @State ua:string="yhxy.html"
  private webviewController: WebviewController = new webview.WebviewController()
  private webviewController2: WebviewController = new webview.WebviewController()
  @State mode: WebDarkMode = WebDarkMode.Auto;

  aboutToAppear(): void {
  }
  privacyText: loginComponentManager.PrivacyText[] = [{
    text: '点击同意表示您已阅读并同意',
    type: loginComponentManager.TextType.PLAIN_TEXT
  }, {
    text: '《TextPaper用户服务协议》 ',
    tag: '用户协议',
    type: loginComponentManager.TextType.RICH_TEXT
  },{
    text: '和',
    type: loginComponentManager.TextType.PLAIN_TEXT
  }, {
    text: '《TextPaper隐私协议》',
    tag: '隐私协议',
    type: loginComponentManager.TextType.RICH_TEXT
  }];
  onChangedUser(){
    if (dataPreferences){
      if (this.user_copy){
        dataPreferences.putSync("user",JSON.stringify(this.user_copy))
        dataPreferences.flushSync()
      }
    }
  }
  build() {
    RelativeContainer() {

    }.bindSheet(this.isShow, this.myBuilder(), {
      detents: [SheetSize.LARGE],
      backgroundColor: Color.Gray,
      blurStyle: BlurStyle.Regular,
      showClose:false,
      enableOutsideInteractive: false, //不允许交互，显示蒙层
      maskColor:$r('sys.color.ohos_id_blur_style_background_ultra_thick_color'),
      preferType: SheetType.CENTER,
      shadow:ShadowStyle.OUTER_DEFAULT_SM,

      shouldDismiss: ((sheetDismiss: SheetDismiss) => {

      })
    })
    .height('100%')
    .width('100%')
  }
  @Builder
  myBuilder() {
    if(this.isShowXieyi){
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
            this.isShowXieyi = false
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
        if (this.isUA){
          Web({
            src: $rawfile(this.ua) ,
            controller: this.webviewController2,
            renderMode: RenderMode.ASYNC_RENDER // 设置渲染模式
          }).width('100%').height('90%').borderRadius(15)
            .darkMode(this.mode)
        }else {
          Web({
            src: $rawfile(this.pa) ,
            controller: this.webviewController,
            renderMode: RenderMode.ASYNC_RENDER // 设置渲染模式
          }).width('100%').height('90%').borderRadius(15)
            .darkMode(this.mode)
        }


      }.height('140%')
      .width('100%').alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.SpaceBetween)
    }
    else{
      if (this.isShowInfoCheck){
        Column() {
          TextInput({
            placeholder:"请输入用户昵称",
            text:this.user_copy?this.user_copy.name:""
          }).onChange((e:string)=>{
            if (this.user_copy) {
              this.user_copy.name=e
            }else{
              this.user_copy=new UserInfo("","")
              this.user_copy.name=e
            }
          }).width('90%').margin(15)
          TextInput({
            placeholder:"请输入用户研究方向（英文）",
            text:this.user_copy?this.user_copy.desp:""

          }).onChange((e:string)=>{
            if (this.user_copy) {
              this.user_copy.desp=e
            }else{
              this.user_copy=new UserInfo("","")
              this.user_copy.desp=e
            }
          }).width('90%').margin(15)
          Button("保存").onClick(e=>{
            this.onChangedUser()
            this.isShowInfoCheck=false
            router.replaceUrl({
              url:"pages/ResponsiveIndex"
            })
          }).width('90%').margin(15)
          Button("暂不保存").buttonStyle(ButtonStyleMode.TEXTUAL).onClick(e=>{
            this.isShowInfoCheck=false
            router.replaceUrl({
              url:"pages/ResponsiveIndex"
            })
          }).width('90%').margin(15)

        }.height('100%')
        .width('100%').alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)

      }else{
        Column(){
          Column(){
            Image($r('app.media.logo')).width('400vp')
          }.height('60%')
          .width('100%').alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
          Column(){
            SymbolGlyph($r("sys.symbol.person_shield_1"))
              .fontSize(30).margin(15)
            Text() {
              ForEach(this.privacyText, (item: loginComponentManager.PrivacyText) => {
                if (item?.type === loginComponentManager.TextType.PLAIN_TEXT && item?.text) {
                  Span(item?.text)
                    .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                    .fontFamily($r('sys.string.ohos_id_text_font_family_regular'))
                    .fontWeight(FontWeight.Regular)
                    .fontSize($r('sys.float.ohos_id_text_size_body3'))
                } else if (item?.type === loginComponentManager.TextType.RICH_TEXT && item?.text) {
                  Span(item?.text)
                    .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
                    .fontFamily($r('sys.string.ohos_id_text_font_family_medium'))
                    .fontWeight(FontWeight.Medium)
                    .fontSize($r('sys.float.ohos_id_text_size_body3'))
                    .focusable(true)
                    .focusOnTouch(true)
                    .onClick(() => {
                      // 应用需要根据item.tag实现协议页面的跳转逻辑
                      if (item.tag==="隐私协议"){
                        this.isShowXieyi = true
                        this.isUA=false

                      }else if (item.tag==="用户协议"){
                        this.isShowXieyi = true
                        this.isUA=true
                      }
                    })
                }
              }, (item: loginComponentManager.PrivacyText) => item.text.toString())
            }
            .width('300vp').margin({ bottom:20 })
            Row(){
              Button("拒绝").buttonStyle(ButtonStyleMode.EMPHASIZED).backgroundColor(
                Color.Gray
              ).width('100vp').onClick(e=>{
                if (dataPreferences) {
                  dataPreferences.putSync("isFirst", false)
                  dataPreferences.flushSync()

                }


              })
              Button("同意").width('100vp').onClick(e=>{
                if (dataPreferences){
                  dataPreferences.putSync("isFirst",false)
                  dataPreferences.putSync("isAgentUA",true)
                  dataPreferences.flushSync()
                  this.isShowInfoCheck = true
                  //  dataPreferences.getSync("isFirst",true) as boolean
                  //     isAgentUA = dataPreferences.getSync("isAgentUA",false) as boolean
                }
              })

            }.width('300vp').alignItems(VerticalAlign.Center).justifyContent(FlexAlign.SpaceBetween)
          }.height('40%')
          .width('100%').alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)

        }.height('100%')
        .width('100%').alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.SpaceBetween)
      }
    }

  }
}