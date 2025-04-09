import { dataPreferences } from "../defaultability/DefaultAbility"
import { webview } from "@kit.ArkWeb"
import { bundleManager } from "@kit.AbilityKit"
import { BusinessError } from "@kit.BasicServicesKit"
import List from "@ohos.util.List"
import { promptAction } from "@kit.ArkUI"
import { paperTime2Str } from "../entity/Paper"

class  MenuItemMine2{
  name:string = ""
  value:string|number = ""
  func:() => void = () => {}

  constructor(name:string,value:string|number ,func:()=>void) {
    this.name = name
    this.value = value
    this.func=func
  }
}
class  MenuItemMine{
  name:string = ""
  func:() => void = () => {}

  constructor(name:string,func:()=>void) {
    this.name = name
    this.func=func
  }
}
export class UserInfo{
  name:string = ""
  desp:string = ""
  constructor(name:string,desp:string) {
    this.name = name
    this.desp=desp
  }
}
export class AppleInfo{
  name:string = ""
  versionCode:number = 0
  versionName:string = ""
  minCompatibleVersionCode:number = 0
  targetVersion:number = 0
  installTime:number = 0
  updateTime:number = 0
  constructor() {

  }
  tolist():List<string|number>{
    let list:List<string|number> = new List();
    list.add(this.name)
    list.add(this.versionCode)
    list.add(this.versionName)
    list.add(this.targetVersion)
    list.add(this.installTime)
    list.add(this.updateTime)

    return list
  }
}
@Component
@Preview
export  struct MinePage {
  @State message: string = '匿名用户';
  @State user:UserInfo|null=null
  @State user_copy:UserInfo|null=null
  @State version: string = '';

  @State menus : MenuItemMine[] = []
  @State menus2 : MenuItemMine2[] = []

  @State isUA:boolean = false
  @State pa:string = "ysxy.html"
  @State ua:string="yhxy.html"
  @State isShowXieyi : boolean = false
  @State isShowUserChanged : boolean = false
  @State isAboutMe : boolean = false
  @State info : AppleInfo   = new AppleInfo()
  private webviewController: WebviewController = new webview.WebviewController()
  @State mode: WebDarkMode = WebDarkMode.Auto;

  @Builder
  myBuilder() {
    Column() {
      if (this.isUA){
        Web({
          src: $rawfile(this.ua) ,
          controller: this.webviewController,
          renderMode: RenderMode.ASYNC_RENDER // 设置渲染模式
        }).width('100%').height('100%').darkMode(this.mode)

      }else {
        Web({
          src: $rawfile(this.pa) ,
          controller: this.webviewController,
          renderMode: RenderMode.ASYNC_RENDER // 设置渲染模式
        }).width('100%').height('100%').darkMode(this.mode)
      }


    }.height('100%')
    .width('100%').alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.SpaceBetween)

  }
  async getMoreInfo(){
    const bundleInfo =  bundleManager.getBundleInfoForSelfSync(
      0
    );
    this.info.name = "TestPaper"
    this.info.versionCode = bundleInfo.versionCode
    this.info.versionName = bundleInfo.versionName
    this.info.minCompatibleVersionCode = bundleInfo.minCompatibleVersionCode
    this.info.installTime = bundleInfo.installTime
    this.info.updateTime = bundleInfo.updateTime
    this.info.targetVersion = bundleInfo.targetVersion
    let lists : string[] = [
      "应用名称","应用版本号","版本名称","目标版本",
      "安装日期","更新日期"
    ]
    let q = this.info.tolist()

    for (let i=0;i<lists.length;i++){
      if (i>=4){
        this.menus2.push(
          new MenuItemMine2(
            lists[i],
            paperTime2Str((q.get(i) as number)/1000),
            () =>{
              promptAction.showToast({
                message:paperTime2Str(q.get(i) as number),
                duration:500
              })

            }
          )
        )
      }else{
        this.menus2.push(
          new MenuItemMine2(
            lists[i],
            q.get(i).toString(),
            () =>{
              promptAction.showToast({
                message:q.get(i).toString(),
                duration:500
              })

            }
          )
        )
      }



    }
    this.menus2.push(
      new MenuItemMine2(
        "软件发行",
      "开放学术共同体",
    () =>{
      promptAction.showToast({
        message:"开放学术共同体",
        duration:500
      })

      })
    )

    this.menus2.push(
      new MenuItemMine2(
        "开源协议",
        "OACL V1",
        () =>{
          promptAction.showToast({
            message:"OACL V1",
            duration:500
          })

        })
    )
  }

  // 获取应用版本号
  async getAppVersion() {
    try {
      const bundleInfo = await bundleManager.getBundleInfoForSelf(0);
      console.log('----版本号', bundleInfo.versionName)
      this.version = bundleInfo.versionName; // 获取版本名称
    } catch (error) {
      console.error('获取版本号失败:', (error as BusinessError).message);
    }
  }
  async aboutToAppear() {
    if (dataPreferences){
      const usertext = dataPreferences.getSync("user","") as string
      if(usertext){
        this.user=JSON.parse(usertext) as UserInfo
      }
    }
    await this.getAppVersion()
    let n : MenuItemMine[] = []
    n.push(new MenuItemMine(
      "隐私协议",() =>{
      this.isShowXieyi=true
      this.isUA=false

    }
    ))
    n.push(new MenuItemMine(
      "用户协议",() =>{
      this.isShowXieyi=true
      this.isUA=true
    }
    ))
    n.push(new MenuItemMine(
      "关于应用",() =>{
      this.isAboutMe=true
    }
    ))
    this.menus = n

  }

  onChangedUser(){
    if (dataPreferences){
      if (this.user_copy){
        dataPreferences.putSync("user",JSON.stringify(this.user_copy))
        dataPreferences.flushSync()
        this.user = this.user_copy
      }
    }
  }
  @Builder
  aboutApplication(){
    Column() {
      Image($r('app.media.logo2')).size({
        width:200,
        height:200
      })
      Grid(){
        ForEach(this.menus2,(item: MenuItemMine2) =>{
          GridItem(){
            Row(){
              Text(item.name).fontSize(15)
              Text(item.value.toString()).fontSize(15)

            }.width('100%').alignItems(VerticalAlign.Center)
            .justifyContent(FlexAlign.SpaceBetween)
            .onClick(e=>{
              item.func()
            }).padding(15)
          }.width('100%')
        })
      }.width('90%').margin('4%').backgroundColor(
        $r('sys.color.ohos_id_color_text_field_sub_bg')
      ).borderRadius('15vp')
    }.height('100%')
    .width('100%').alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)

  }
  @Builder
  myChange(){
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
        this.isShowUserChanged=false
      }).width('90%').margin(15)


    }.height('100%')
    .width('100%').alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)

  }
  build() {
    RelativeContainer() {
      Column(){
        if (this.user){
          Button(){
            Text(this.user.name.charAt(0)).fontSize('22fp')
          }.type(ButtonType.Circle).size({
            width:"100vp",
            height:"100vp"
          }).onClick(e=>{
            this.isShowUserChanged=true
            this.user_copy=this.user
          })
          .bindSheet(this.isShowUserChanged, this.myChange(), {
            detents: [SheetSize.LARGE],
            backgroundColor: Color.Gray,
            blurStyle: BlurStyle.Regular,
            showClose:true,
            enableOutsideInteractive: false, //不允许交互，显示蒙层
            maskColor:$r('sys.color.ohos_id_blur_style_background_ultra_thick_color'),
            preferType: SheetType.CENTER,
            shadow:ShadowStyle.OUTER_DEFAULT_SM,

            shouldDismiss: ((sheetDismiss: SheetDismiss) => {
              this.isShowUserChanged=false
              this.onChangedUser()
              sheetDismiss.dismiss()
            })
          })
          Text(this.user.name)
            .fontSize('32fp')
            .fontWeight(FontWeight.Bold)
            .alignRules({
              center: { anchor: '__container__', align: VerticalAlign.Center },
              middle: { anchor: '__container__', align: HorizontalAlign.Center }
            })
          Text(this.user.desp)
            .fontSize('22fp')
            .fontStyle(FontStyle.Italic)
            .fontWeight(FontWeight.Bold)
            .alignRules({
              center: { anchor: '__container__', align: VerticalAlign.Center },
              middle: { anchor: '__container__', align: HorizontalAlign.Center }
            })
        }else{
          Button(){
            Image($r('app.media.icons')).size({
              width:"100vp",
              height:"100vp"
            })
          }.type(ButtonType.Circle).size({
            width:"100vp",
            height:"100vp"
          }).onClick(e=>{
            this.isShowUserChanged=true
            this.user_copy=this.user

          })
          .bindSheet(this.isShowUserChanged, this.myChange(), {
            detents: [SheetSize.LARGE],
            backgroundColor: Color.Gray,
            blurStyle: BlurStyle.Regular,
            showClose:true,
            enableOutsideInteractive: false, //不允许交互，显示蒙层
            maskColor:$r('sys.color.ohos_id_blur_style_background_ultra_thick_color'),
            preferType: SheetType.CENTER,
            shadow:ShadowStyle.OUTER_DEFAULT_SM,

            shouldDismiss: ((sheetDismiss: SheetDismiss) => {
              this.isShowUserChanged=false
              this.onChangedUser()
              sheetDismiss.dismiss()
            })
          })
          .bindSheet(this.isAboutMe, this.aboutApplication(), {
            detents: [SheetSize.LARGE],
            backgroundColor: Color.Gray,
            blurStyle: BlurStyle.Regular,
            showClose:true,
            enableOutsideInteractive: false, //不允许交互，显示蒙层
            maskColor:$r('sys.color.ohos_id_blur_style_background_ultra_thick_color'),
            preferType: SheetType.CENTER,
            shadow:ShadowStyle.OUTER_DEFAULT_SM,
            onAppear:(async ()=>{
              await this.getMoreInfo()
            }),
            shouldDismiss: ((sheetDismiss: SheetDismiss) => {
              this.isAboutMe=false
              sheetDismiss.dismiss()
            })
          })
          Text(this.message)
            .id('MinePageHelloWorld')
            .fontSize('32fp')
            .fontWeight(FontWeight.Bold)
            .alignRules({
              center: { anchor: '__container__', align: VerticalAlign.Center },
              middle: { anchor: '__container__', align: HorizontalAlign.Center }
            })
        }
        Grid(){
          ForEach(this.menus,(item: MenuItemMine) =>{
            GridItem(){
              Row(){
                Text(item.name).fontSize(20)
              }.width('100%').alignItems(VerticalAlign.Center).onClick(e=>{
                item.func()
              })
              .justifyContent(FlexAlign.Center).padding(15)
            }.width('100%')
          })
        }.width('90%').margin('4%').backgroundColor(
          $r('sys.color.ohos_id_color_text_field_sub_bg')
        ).borderRadius('15vp')

        Text("TestPaper v"+this.version+" For HarmonyOS").fontSize(15)
          .fontWeight(FontWeight.Lighter).fontColor(Color.Gray)
          .fontStyle(FontStyle.Italic)
        Text("Powered by OpenAcademic Community").fontSize(15)
          .fontWeight(FontWeight.Lighter).fontColor(Color.Gray)
          .fontStyle(FontStyle.Italic)


      }.height('100%').padding({
        top:"50vp"
      })
      .width('100%').alignItems(HorizontalAlign.Center).bindSheet(this.isShowXieyi, this.myBuilder(), {
        detents: [SheetSize.LARGE],
        backgroundColor: Color.Gray,
        blurStyle: BlurStyle.Regular,
        showClose:true,
        enableOutsideInteractive: false, //不允许交互，显示蒙层
        maskColor:$r('sys.color.ohos_id_blur_style_background_ultra_thick_color'),
        preferType: SheetType.CENTER,
        shadow:ShadowStyle.OUTER_DEFAULT_SM,

        shouldDismiss: ((sheetDismiss: SheetDismiss) => {
          this.isShowXieyi=false
          sheetDismiss.dismiss()
        })
      })

    }
    .height('100%')
    .width('100%')
  }
}