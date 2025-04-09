import { webview } from '@kit.ArkWeb';
import { it } from '@ohos/hypium';

@Observed
export class WebObj{
  text:string = ""
  constructor(text:string) {
    this.text = text
  }
}

@Component
export struct WebComponent {
  @Prop obj : string
  aboutToAppear(): void {
  }
  controller: webview.WebviewController = new webview.WebviewController();



  build() {
    Column() {
      // 加载沙箱路径文件。
      Web({
        src: '',
        controller: this.controller
      }).onControllerAttached(() => {
        this.controller.loadUrl($rawfile("output.html"));
        let js_str = "document.getElementById('mainContent').innerHTML = \""+encodeURIComponent(this.obj)+"\";"
        console.debug("sds",js_str.toString())

        this.controller.runJavaScript(js_str).then(e=>
          console.debug("sds",e.toString())
        );
        js_str = "MathJax.Hub.Queue([\"Typeset\", MathJax.Hub]);"
        this.controller.runJavaScript(js_str).then(e=>
        console.debug("sds",e.toString())
        );

      })
        .height("100%")
        .onConsole((event)=>{
          return false;
        })
    }
  }
}
