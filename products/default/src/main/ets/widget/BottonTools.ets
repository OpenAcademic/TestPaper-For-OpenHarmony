import { store } from "../defaultability/DefaultAbility";
import { relationalStore, uniformTypeDescriptor } from "@kit.ArkData";
import { Paper } from "../entity/Paper";
import { systemShare } from "@kit.ShareKit";
@Component
export struct BottomTools2{
  @Prop aid: string;
  @State isSaving: boolean = false;
  onSave: () => void= () => {};
  onRead: () => void= () => {};
  onCancel: () => void = () => {};
  onDelete: () => void = () => {};
  onShare: () => void = () => {};
  onBackHome: () => void = () => {};
  async aboutToAppear() {
    if (store){
      let mystore = store as relationalStore.RdbStore;
      const res = await Paper.get_isExistByArxivId(mystore,this.aid)
      this.isSaving = res
    }
  }
  build() {
    Row({space:5}){
      // 右边两个按钮，左边是 收藏的图标 和 分享的图标
      Row({space:10}){
        Image(this.isSaving?$r('app.media.save_yes'):$r('app.media.save'))
          .width(40).height(40).onClick(e=>{
          if (this.isSaving) {
            this.onDelete();
          }else{
            this.onSave();
          }
        })
        Image($r('app.media.share'))
          .width(40).height(40).onClick(e=>{
          this.onShare();

        })
        Image($r('app.media.shouye'))
          .width(40).height(40).onClick(e=>{
          this.onBackHome();

        })
      }
      // 左边三个按钮，分别是 阅读、取消 和 删除
      Row(){
        Button('现在阅读').onClick(e=>{this.onRead()})
      }

    }.width('100%')
    .height(60).margin({bottom:20})
    .borderRadius(10).alignItems(VerticalAlign.Center).justifyContent(FlexAlign.SpaceBetween)

  }
}


@Component
export struct BottomTools{
  @Prop aid: string;
  @State isSaving: boolean = false;
  onSave: () => void= () => {};
  onRead: () => void= () => {};
  onCancel: () => void = () => {};
  onDelete: () => void = () => {};
  onShare: () => void = () => {};
  async aboutToAppear() {
    if (store){
      let mystore = store as relationalStore.RdbStore;
      const res = await Paper.get_isExistByArxivId(mystore,this.aid)
      this.isSaving = res
    }
  }
  build() {
    Row({space:5}){
      // 右边两个按钮，左边是 收藏的图标 和 分享的图标
      Row({space:10}){
        Image(this.isSaving?$r('app.media.save_yes'):$r('app.media.save'))
        .width(40).height(40).onClick(e=>{
          if (this.isSaving) {
            this.onDelete();
          }else{
            this.onSave();
          }
        })
        Image($r('app.media.share'))
        .width(40).height(40).onClick(e=>{
          this.onShare();

        })
      }
      // 左边三个按钮，分别是 阅读、取消 和 删除
      Row(){
        Button('现在阅读').onClick(e=>{this.onRead()})
      }

    }.width('100%')
    .height(60).margin({bottom:20})
    .borderRadius(10).alignItems(VerticalAlign.Center).justifyContent(FlexAlign.SpaceBetween)

  }
}