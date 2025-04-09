import { pdfViewManager } from "@kit.PDFKit"

@Component
export struct SideBar{
  @Prop select_text : string = ''
  onAddText : () => void = ()=>{}

  build() {
    Column({space:15}){
      Text("翻译")
        .fontSize(20).width('100%').fontWeight('bold').textAlign(TextAlign.Center)
      Scroll(){
        Text(this.select_text).wordBreak(WordBreak.BREAK_ALL)
          .fontSize(15).width('100%')
      }.scrollable(ScrollDirection.Vertical).width('100%').height(300)

      Button('Click me').onClick(()=>{
        this.onAddText()
      })





    }.width('100%').padding('3%').justifyContent(FlexAlign.Start)
    .height('100%').shadow({
      color:Color.Gray,
      radius:20
    }).borderRadius(15)
  }
}


@Component
export struct Pizhu{
  @State controller: pdfViewManager.PdfController = new pdfViewManager.PdfController();
  @State list: string[] = []
  aboutToAppear(): void {

  }

  build(){
    Column({space:15}){
      Text("翻译")
        .fontSize(20).width('100%').fontWeight('bold').textAlign(TextAlign.Center)






    }.width('100%').padding('3%').justifyContent(FlexAlign.Start)
    .height('100%').shadow({
      color:Color.Gray,
      radius:20
    }).borderRadius(15)
  }
}