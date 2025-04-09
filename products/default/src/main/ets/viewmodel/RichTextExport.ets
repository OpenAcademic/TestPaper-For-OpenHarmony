
export function text2rich(text:string){
  return "<!DOCTYPE html>\n" +
    "\n" +
    "<html>\n" +
    "<head>\n" +
    "    <title>解数学题</title>\n" +
    "    <script src=\"https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.7/MathJax.js?config=TeX-MML-AM_CHTML\"></script>\n" +
    "    <meta charset=\"utf-8\"/>\n" +
    "</head>\n" +
    "<body>\n" +
    "<h3  id=\"mainContent\">\n" + text+
    "</h3></body>\n" +
    "</html>"
}