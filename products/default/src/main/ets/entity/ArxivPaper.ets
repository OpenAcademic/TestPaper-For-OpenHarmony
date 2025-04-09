
export class TranslateRes {
  code: number
  msg: string
  data?: string
  constructor(
    code: number,message: string
  ) {
    this.code = code
    this.msg = message
  }
}
export class ArxivBase {
  code: number
  msg: string
  data?: ArxivPaper[]
  constructor(
    code: number,message: string
  ) {
    this.code = code
    this.msg = message
  }
}
@Observed
export class ArxivPaper {
  title: string
  id: string
  updated?: number
  licenses?: string
  summary?: string
  author?:string[]
  category?:string[]
  doi?: string
  journal?: string

  constructor(
    title: string,id: string
  ) {
    this.id = id
    this.title = title
  }
}
