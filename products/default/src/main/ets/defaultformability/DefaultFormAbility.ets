import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { ArxivConfig, ArxivType, getPapers } from '../api/ArxivApi';
import { paperTime2Str } from '../entity/Paper';
import { List } from '@kit.ArkTS';
import { ArxivPaper } from '../entity/ArxivPaper';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { preferences } from '@kit.ArkData';
import { UserInfo } from '../view/MinePage';


async function getPapersToday( data:preferences.Preferences){
  let result : ArxivPaper[] | null = null
  if (data){
    const usertext = data.getSync("user","") as string
    if(usertext){
      let user=JSON.parse(usertext) as UserInfo
      if (user.desp){
        result = await getPapers(
          new ArxivConfig(ArxivType.ALL,user.desp).toTiaojianString())
      }else{
        result = await getPapers(new ArxivConfig(ArxivType.ALL,"").toTiaojianString())
      }
    }else{
      result = await getPapers(new ArxivConfig(ArxivType.ALL,"").toTiaojianString())

    }
  }else{
    result = await getPapers(new ArxivConfig(ArxivType.ALL,"").toTiaojianString())

  }


  console.log("card",result?.toString())
  if (result){
    return result
  }else{
    let list : ArxivPaper[] = []
    return list;
  }
}


interface GeneratedObjectLiteralInterface_1 {
  t1_t: string;
  t1_d: string;
  t2_t: string;
  t2_d: string;
  t3_t: string;
  t3_d: string;
  t1_id:string;
  t2_id:string;
  t3_id:string;
  isEmpty:boolean

}

export default class DefaultFormAbility extends FormExtensionAbility {
  onAddForm(want: Want) {

    // Called to return a FormBindingData object.
    const formData: GeneratedObjectLiteralInterface_1 = {
      t1_t:"Q-Insight: Understanding Image Quality via Visual Reinforcement Learning",
      t1_d:"Mon, 31 Mar 2025",
      t1_id:"2503.22679",
      t2_id:"2503.22678",
      t3_id:"2503.22677",
      t2_t:"Self-Evolving Multi-Agent Simulations for Realistic Clinical Interactions",
      t2_d:"Mon, 31 Mar 2025",
      t3_t:"DSO: Aligning 3D Generators with Simulation Feedback for Physical Soundness",
      t3_d:"Mon, 31 Mar 2025",
      isEmpty:false
    };
    return formBindingData.createFormBindingData(formData);
  }

  onCastToNormalForm(formId: string) {
    // Called when the form provider is notified that a temporary form is successfully
    // converted to a normal form.
    this.onUpdateData(formId)
  }

  async onUpdateData(formId: string){
    let options: preferences.Options = { name: 'litenote' };
    let dataPreferences = preferences.getPreferencesSync(this.context,
      options);
    const result = await getPapersToday(dataPreferences);
    if (result.length>3){
      const formData: GeneratedObjectLiteralInterface_1 = {
        t1_t:result[0].title,
        t1_d:paperTime2Str(result[0].updated),
        t2_t:result[1].title,
        t2_d:paperTime2Str(result[1].updated),
        t3_t:result[2].title,
        t3_d:paperTime2Str(result[2].updated),
        t1_id:result[0].id,
        t2_id:result[1].id,
        t3_id:result[2].id,
        isEmpty:false
      };

      formProvider.updateForm(
        formId,formBindingData.createFormBindingData(formData)
      ).then(() => console.info('卡片内更新成功'))
    }else{
      const formData: GeneratedObjectLiteralInterface_1 = {
        t1_t:"Q-Insight: Understanding Image Quality via Visual Reinforcement Learning",
        t1_d:"Mon, 31 Mar 2025",
        t1_id:"2503.22679",
        t2_id:"2503.22678",
        t3_id:"2503.22677",
        t2_t:"Self-Evolving Multi-Agent Simulations for Realistic Clinical Interactions",
        t2_d:"Mon, 31 Mar 2025",
        t3_t:"DSO: Aligning 3D Generators with Simulation Feedback for Physical Soundness",
        t3_d:"Mon, 31 Mar 2025",
        isEmpty:true
      };
      formProvider.updateForm(
        formId,formBindingData.createFormBindingData(formData)
      ).then(() => console.info('卡片内更新成功'))
    }
  }

  onUpdateForm(formId: string) {
    // Called to notify the form provider to update a specified form.
    this.onUpdateData(formId)
  }

  onFormEvent(formId: string, message: string) {
    // Called when a specified message event defined by the form provider is triggered.
    this.onUpdateData(formId)
  }

  onRemoveForm(formId: string) {
    // Called to notify the form provider that a specified form has been destroyed.
  }

  onAcquireFormState(want: Want) {
    // Called to return a {@link FormState} object.
    return formInfo.FormState.READY;
  }
}