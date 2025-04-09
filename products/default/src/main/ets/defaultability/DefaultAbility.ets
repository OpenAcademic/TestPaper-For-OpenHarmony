import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

import { distributedKVStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { preferences } from '@kit.ArkData';
import { relationalStore } from '@kit.ArkData';
import { Paper } from '../entity/Paper';


import AbilityStage from '@ohos.app.ability.AbilityStage';
import { PaperNote } from '../entity/PaperNote';


export let store: relationalStore.RdbStore | undefined = undefined;
export let dataPreferences: preferences.Preferences | null = null;
export let kvManager: distributedKVStore.KVManager | undefined = undefined;
export let kvStore: distributedKVStore.SingleKVStore | null = null;
export let selectPage: string;
export  let  stoage: LocalStorage = new LocalStorage();
export  let isAgentUA : boolean = false
const DOMAIN = 0x0000;

export default class DefaultAbility extends UIAbility {
  private id:string = ""
  private isFirst : boolean = true
  private currentWindowStage: window.WindowStage | null = null;
  initDB(){
    let context = this.context

    const kvManagerConfig: distributedKVStore.KVManagerConfig = {
      context: context,
      bundleName: 'cn.tw.sar.note'
    };
    try {
      // 创建KVManager实例
      kvManager = distributedKVStore.createKVManager(kvManagerConfig);
      console.info('Succeeded in creating KVManager.');
      try {
        const options: distributedKVStore.Options = {
          createIfMissing: true,
          encrypt: false,
          backup: false,
          autoSync: false,
          kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
          securityLevel: distributedKVStore.SecurityLevel.S2,
        };
        kvManager.getKVStore('note', options, (err: BusinessError, store: distributedKVStore.SingleKVStore) => {
          if (err) {
            console.error(`Failed to get KVStore.code is ${err.code},message is ${err.message}`);
            return;
          }
          console.info("Succeeded in getting KVStore");
          kvStore = store;
        });
      } catch (e) {
        let error = e as BusinessError;
        console.error(`An unexpected error occurred.code is ${error.code},message is ${error.message}`);
      }
      // 继续创建获取数据库
    } catch (e) {
      let error = e as BusinessError;
      console.error(`Failed to create KVManager. Code:${error.code},message:${error.message}`);
    }

    let options: preferences.Options = { name: 'litenote' };
    dataPreferences = preferences.getPreferencesSync(this.context,
      options);
    this.isFirst = dataPreferences.getSync("isFirst",true) as boolean
    isAgentUA = dataPreferences.getSync("isAgentUA",false) as boolean

    if (!this.isFirst){
      selectPage="HomePage"
    }

    const STORE_CONFIG: relationalStore.StoreConfig = {
      name: "paper.db",
      securityLevel: relationalStore.SecurityLevel.S1
    };

    relationalStore.getRdbStore(this.context, STORE_CONFIG, (err: BusinessError, rdbStore: relationalStore.RdbStore) => {
      store = rdbStore;
      // 设置数据库版本
      if(store != undefined) {
        (store as relationalStore.RdbStore).version = 1;
        // 获取数据库版本
        console.info(`RdbStore version is ${store.version}`);
        // 获取数据库是否重建
        console.info(`RdbStore rebuilt is ${store.rebuilt}`);
        if(store != undefined) {
          let mStore = (store as relationalStore.RdbStore);
          Paper.build_create_table_sql(mStore);
          console.info(`Create table Paper successfully`);

          const res = PaperNote.build_create_table_sql(mStore)
          console.info(`Create table PaperNote successfully` + res);

        }
      }
      if (err) {
        console.error(`Get RdbStore failed, code is ${err.code},message is ${err.message}`);
        return;
      }
      console.info('Get RdbStore successfully.');
    })

  }
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    if (want?.parameters?.params) {
      // want.parameters.params 对应 postCardAction() 中 params 内容
      let params: Record<string, Object> = JSON.parse(want.parameters.params as string);
      selectPage = params.targetPage as string;
      console.log("Res",params.id)
      this.id=params.id as string

    }
    this.initDB()


    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);

    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {

    if (want?.parameters?.params) {
      // want.parameters.params 对应 postCardAction() 中 params 内容
      let params: Record<string, Object> = JSON.parse(want.parameters.params as string);
      selectPage = params.targetPage as string;
      console.log("Res",params.id)
      this.id=params.id as string
    }
    if (this.currentWindowStage !== null) {
      this.onWindowStageCreate(this.currentWindowStage);
    }
  }


  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    // Main window is created, set main page for this ability
    let targetPage: string;
    // 根据传递的targetPage不同，选择拉起不同的页面
    switch (selectPage) {
      case 'PaperDetailPage':
        console.info("res",this.id)
        stoage.setOrCreate('id', this.id);

        targetPage = 'pages/PaperDetailPage'; //与实际的UIAbility页面路径保持一致
        break;
      case "HomePage":
        targetPage = 'pages/ResponsiveIndex';
        break;
      default:
        targetPage = 'pages/ResponsiveIndex'; //与实际的UIAbility页面路径保持一致
    }
    if (this.currentWindowStage === null) {
      this.currentWindowStage = windowStage;
    }

    windowStage.loadContent(targetPage,stoage ,(err, data) => {
      if (err.code) {
        return;
      }
      let windowClass: window.Window = windowStage.getMainWindowSync(); // 获取应用主窗口
      // 1. 设置窗口全屏
      // 1. 设置窗口全屏
      let isLayoutFullScreen = true;
      windowClass.setWindowLayoutFullScreen(isLayoutFullScreen).then(() => {
        console.info('Succeeded in setting the window layout to full-screen mode.');
      }).catch((err: BusinessError) => {
        console.error('Failed to set the window layout to full-screen mode. Cause:' + JSON.stringify(err));
      });
      let type = window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR; // 以导航条避让为例
      let avoidArea = windowClass.getWindowAvoidArea(type);
      let bottomRectHeight = avoidArea.bottomRect.height; // 获取到导航条区域的高度
      AppStorage.setOrCreate('bottomRectHeight', bottomRectHeight);

      type = window.AvoidAreaType.TYPE_SYSTEM; // 以状态栏避让为例
      avoidArea = windowClass.getWindowAvoidArea(type);
      let topRectHeight = avoidArea.topRect.height; // 获取状态栏区域高度
      AppStorage.setOrCreate('topRectHeight', topRectHeight);
      // 2. 设置导航条隐藏
      windowClass.on('avoidAreaChange', (data) => {
        if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
          let topRectHeight = data.area.topRect.height;
          AppStorage.setOrCreate('topRectHeight', topRectHeight);
        } else if (data.type == window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
          let bottomRectHeight = data.area.bottomRect.height;
          AppStorage.setOrCreate('bottomRectHeight', bottomRectHeight);
        }
      });
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}