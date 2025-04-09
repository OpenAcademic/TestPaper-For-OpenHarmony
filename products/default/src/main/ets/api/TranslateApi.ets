import { http } from "@kit.NetworkKit";
import { ArxivBase, ArxivPaper, TranslateRes } from "../entity/ArxivPaper";
import { request, systemDateTime } from "@kit.BasicServicesKit";
import { common } from "@kit.AbilityKit";
import { fileIo, picker } from "@kit.CoreFileKit";






export async function getTranslateRes(strs: string,from:string,to:string): Promise<string | null> {
  let httpRequest = http.createHttp();
  // 将 空格转义
  let url_strs = encodeURIComponent(strs)
  let uri = "https://note.wxd2zrx.top/translate"

  console.info("vdf",uri)

  try {
    let response = await httpRequest.request(
      uri,
      {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json'
        },
        // query = data.get("query")
        //     from_lang = data.get("from_lang")
        //     to_lang = data.get("to_lang")
        extraData: JSON.stringify({
          query: strs,
          from_lang:from,
          to_lang:to
        })
      }
    )

    if (response.responseCode === 200) {
      console.info("vdf",response.result.toString())
      let result = JSON.parse(response.result.toString()) as TranslateRes
      return result.data as string
    }
    return null
  } catch (err) {
    console.error(`Failed to parse code: ${err.code}`)
    return null
  } finally {
    httpRequest.destroy()
  }
}