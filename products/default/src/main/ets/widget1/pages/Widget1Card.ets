


@Entry
@Component
 struct Widget1Card {
  @LocalStorageProp('t1_d') singleIDYText3_1: string = '987万热度'
  @LocalStorageProp('t1_id') singleIDYText1_id: string = ''
  @LocalStorageProp('t2_id') singleIDYText2_id: string = ''
  @LocalStorageProp('t3_id') singleIDYText3_id: string = ''

  @LocalStorageProp('t2_t') singleIDYText2_2: string = '那些长期不上班的人最后都怎么样了'
  @State singleIDYText1_3_static: string = '03'
  @LocalStorageProp('t2_d') singleIDYText3_2: string = '234万热度'
  @LocalStorageProp('t3_t') singleIDYText2_3: string = '欧洲姑娘用凤凰传奇歌词学习中文'
  @State singleIDYText1_1_static: string = '01'
  @LocalStorageProp('t1_t') singleIDYText2_1: string = '小鹏P7超长续航706km'
  @State singleIDYText1_2_static: string = '02'
  @State backgroundImg: Resource = $r('app.media.backage')
  @LocalStorageProp('isEmpty') isEmpty: boolean = false

  @LocalStorageProp('t3_d') singleIDYText3_3: string = '200万热度'
  @LocalStorageProp('textMainTitleX') textMainTitleX: string = '每日Arxiv榜'
  ClickToSingleIDTextTarget1 = () : void => {
    postCardAction(this, {
      "action": "router",
      // Configuring the UIAbility name for jumping.
      'abilityName': 'DefaultAbility',
      // Configuring the parameters to be transferred.
      "params": {
        'targetPage': 'PaperDetailPage',
        'id':this.singleIDYText1_id
      }
    });
  }
  ClickToSingleIDTextTarget2 = () : void => {
    postCardAction(this, {
      "action": "router",
      // Configuring the UIAbility name for jumping.
      'abilityName': 'DefaultAbility',
      // Configuring the parameters to be transferred.
      "params": {
        'targetPage': 'PaperDetailPage',
        'id':this.singleIDYText2_id
      }
    });
  }
  ClickToSingleIDTextTarget3 = () : void => {
    postCardAction(this, {
      "action": "router",
      // Configuring the UIAbility name for jumping.
      'abilityName': 'DefaultAbility',
      // Configuring the parameters to be transferred.
      "params": {
        'targetPage': 'PaperDetailPage',
        'id':this.singleIDYText3_id
      }
    });
  }

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Stack({ alignContent: Alignment.BottomEnd }) {
        Column() {
          Row() {
            Text(this.textMainTitleX)
              .fontSize('18')
              .fontWeight(FontWeight.Bold)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .maxLines(1)
              .flexShrink(1)
            Image($r('app.media.repeat_easyi')).width(30).height(30).onClick(e=>{
              postCardAction(this, {
                "action": "message",
                "params": {
                  'targetPage': 'page1'
                }
              })
            })
          }
          .margin({ bottom: '12' })
          .width('100%')
          .alignSelf(ItemAlign.Start)
          .justifyContent(FlexAlign.SpaceBetween)
          if (this.isEmpty){
            Column(){
              Text("数据为空")
            }.layoutWeight(1)
          }else{
            List() {
              ListItem() {
                Row() {
                  Text(this.singleIDYText1_1_static)
                    .width('25')
                    .fontColor(Color.Black)
                    .fontSize('14')
                    .fontWeight(FontWeight.Medium)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .maxLines(1)
                  Text(this.singleIDYText2_1)
                    .layoutWeight(1)
                    .fontColor(Color.Black)
                    .fontSize('14')
                    .fontWeight(FontWeight.Medium)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .maxLines(1)
                  Text(this.singleIDYText3_1)
                    .constraintSize({ maxWidth: '60' })
                    .fontColor(Color.Gray)
                    .fontSize('10')
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .maxLines(1)
                }
                .width('100%')
                .onClick(this.ClickToSingleIDTextTarget1)
              }
              .width('100%')
              .height('33%')
              ListItem() {
                Row() {
                  Text(this.singleIDYText1_2_static)
                    .width('25')
                    .fontColor(Color.Black)
                    .fontSize('14')
                    .fontWeight(FontWeight.Medium)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .maxLines(1)
                  Text(this.singleIDYText2_2)
                    .layoutWeight(1)
                    .fontColor(Color.Black)
                    .fontSize('14')
                    .fontWeight(FontWeight.Medium)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .maxLines(1)
                  Text(this.singleIDYText3_2)
                    .constraintSize({ maxWidth: '60' })
                    .fontColor(Color.Gray)
                    .fontSize('10')
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .maxLines(1)
                }
                .width('100%')
                .onClick(this.ClickToSingleIDTextTarget2)
              }
              .width('100%')
              .height('33%')
              ListItem() {
                Row() {
                  Text(this.singleIDYText1_3_static)
                    .width('25')
                    .fontColor(Color.Black)
                    .fontSize('14')
                    .fontWeight(FontWeight.Medium)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .maxLines(1)
                  Text(this.singleIDYText2_3)
                    .layoutWeight(1)
                    .fontColor(Color.Black)
                    .fontSize('14')
                    .fontWeight(FontWeight.Medium)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .maxLines(1)
                  Text(this.singleIDYText3_3)
                    .constraintSize({ maxWidth: '60' })
                    .fontColor(Color.Gray)
                    .fontSize('10')
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .maxLines(1)
                }
                .width('100%')
                .onClick(this.ClickToSingleIDTextTarget3)
              }
              .width('100%')
              .height('33%')
            }
            .width('100%')
            .layoutWeight(1)
          }

        }
        .width('100%')
        .height('100%')
      }

    }
    .backgroundImage(this.backgroundImg)
    .backgroundImageSize({ width: '100%', height: '100%' })
    .padding('12')
    .width('100%')
    .height('100%')
  }
}



