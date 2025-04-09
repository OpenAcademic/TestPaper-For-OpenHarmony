import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { abilityAccessCtrl, bundleManager, common, Permissions } from '@kit.AbilityKit';

async function supportProcessNotify(): Promise<boolean> {
  return await notificationManager.isSupportTemplate('downloadTemplate')
}
export async function requestNotifiesPers(context:common.UIAbilityContext): Promise<boolean> {
  let issupposed = await supportProcessNotify()
  console.info("issupposed",issupposed)
  if (issupposed) {
    const data = await notificationManager.isNotificationEnabled()
    if(!data){
      const res = await notificationManager.requestEnableNotification(context)
      return await notificationManager.isNotificationEnabled()
    }
    return false
  }
  return false

}

export function buildNotifyTemp(
  id:number,
  file_title:string,
  fileName:string,
  progressValue:number,

): notificationManager.NotificationRequest {
  let notificationRequest: notificationManager.NotificationRequest = {
    id: id,
    content: {
      notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
      normal: {
        title: '下载进度',
        text: '下载进度',
        additionalText: '下载进度'
      }
    },
    // 构造进度条模板，name字段当前需要固定配置为downloadTemplate
    template: {
      name: 'downloadTemplate',
      data: { title: file_title, fileName: fileName, progressValue: progressValue }
    }
  };
  return notificationRequest;
}

export async  function checkPermissionGrant(permission: Permissions): Promise<abilityAccessCtrl.GrantStatus> {
  let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
  let grantStatus: abilityAccessCtrl.GrantStatus = abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;

  // 获取应用程序的accessTokenID
  let tokenId: number = 0;
  try {
    let bundleInfo: bundleManager.BundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
    let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
    tokenId = appInfo.accessTokenId;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to get bundle info for self. Code is ${err.code}, message is ${err.message}`);
  }

  // 校验应用是否被授予权限
  try {
    grantStatus = await atManager.checkAccessToken(tokenId, permission);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to check access token. Code is ${err.code}, message is ${err.message}`);
  }

  return grantStatus;
}
export const permissions: Array<Permissions> = ['ohos.permission.READ_WRITE_DOCUMENTS_DIRECTORY','ohos.permission.READ_WRITE_DOWNLOAD_DIRECTORY'];
// 使用UIExtensionAbility：将common.UIAbilityContext 替换为common.UIExtensionContext
export function reqPermissionsFromUser(permissions: Array<Permissions>, context: common.UIAbilityContext): void {
  let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
  // requestPermissionsFromUser会判断权限的授权状态来决定是否唤起弹窗
  atManager.requestPermissionsFromUser(context, permissions).then((data) => {
    let grantStatus: Array<number> = data.authResults;
    let length: number = grantStatus.length;
    for (let i = 0; i < length; i++) {
      if (grantStatus[i] === 0) {
        // 用户授权，可以继续访问目标操作
      } else {
        // 用户拒绝授权，提示用户必须授权才能访问当前页面的功能，并引导用户到系统设置中打开相应的权限
        return;
      }
    }
    // 授权成功
  }).catch((err: BusinessError) => {
    console.error(`Failed to request permissions from user. Code is ${err.code}, message is ${err.message}`);
  })
}