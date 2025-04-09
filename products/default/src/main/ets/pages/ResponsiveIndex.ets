import { ResponsiveLayout } from './ResponsiveLayout'

/**
 * ResponsiveIndex is the entry of the responsive layout pages.
 */
@Entry
@Component
struct ResponsiveIndex {
  @StorageProp('bottomRectHeight')
  bottomRectHeight: number = 0;
  @StorageProp('topRectHeight')
  topRectHeight: number = 0;
  build() {
    Column() {
      ResponsiveLayout()
    }
  }
}