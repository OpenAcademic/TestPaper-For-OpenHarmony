import * as CommonConstants from '../constants/CommonConstants';
import { TabBarItem } from './TabBarItem';

/**
 * Binds data to components and provides interfaces.
 */
export class TabsViewModel {
  /**
   * Get item information for the tab.
   *
   * @return {Array<TabBarItem>} tabItems
   */
  getTabData(): TabBarItem[] {
    const tabItems: TabBarItem[] = [];
    const itemInfo: TabBarItem = new TabBarItem();
    itemInfo.id = 0;
    itemInfo.name = $r('app.string.home');
    itemInfo.icon = $r("app.media.shouye_un");
    itemInfo.selectIcon = $r('app.media.shouye');
    tabItems.push(itemInfo);

    const itemInfo4: TabBarItem = new TabBarItem();
    itemInfo4.id = 1;
    itemInfo4.name = $r('app.string.find');
    itemInfo4.icon = $r("app.media.fxu");
    itemInfo4.selectIcon = $r('app.media.fx');
    tabItems.push(itemInfo4);

    /***
     const itemInfo2: TabBarItem = new TabBarItem();
     itemInfo2.id = 2;
     itemInfo2.name = $r('app.string.zonglan');
     itemInfo2.icon = $r("app.media.zonglan_2");
     itemInfo2.selectIcon = $r('app.media.zonglan');
     tabItems.push(itemInfo2);
     */

    const itemInfo3: TabBarItem = new TabBarItem();
    itemInfo3.id = 3;
    itemInfo3.name = $r('app.string.mine');
    itemInfo3.icon = $r("app.media.wode_active_2");
    itemInfo3.selectIcon = $r("app.media.wode_active");
    tabItems.push(itemInfo3);
    return tabItems;
  }
}

const tabsViewModel = new TabsViewModel();

export default tabsViewModel;