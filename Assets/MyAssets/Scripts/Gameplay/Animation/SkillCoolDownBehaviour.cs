using UnityEngine;

public class SkillCoolDownBehaviour : StateMachineBehaviour {
  public string skill_id;
  [HideInInspector] public SkillCDTimer cd_timer;
  override public void OnStateEnter(Animator animator, AnimatorStateInfo stateInfo, int layerIndex) {
    if (cd_timer != null) {
      cd_timer.SetTimer();
    }
  }
}
