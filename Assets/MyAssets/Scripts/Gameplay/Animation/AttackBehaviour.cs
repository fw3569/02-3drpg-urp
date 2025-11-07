using UnityEngine;

public class AttackBehaviour : StateMachineBehaviour {
  private GameObject m_weapon;
  public string skill_id;
  override public void OnStateEnter(Animator animator, AnimatorStateInfo stateInfo, int layerIndex) {
    m_weapon = animator.GetComponent<CreatureBody>().weapon;
    if (m_weapon != null) {
      m_weapon.GetComponent<Collider>().enabled = true;
      AttackBox atkbox = m_weapon.GetComponent<AttackBox>();
      atkbox.UpdateSeq();
      atkbox.atk = animator.GetComponent<CreatureBody>().status.atk;
    }
  }
  override public void OnStateExit(Animator animator, AnimatorStateInfo stateInfo, int layerIndex) {
    if (animator.TryGetComponent(out EnemyAI enemy_ai)) {
      enemy_ai.attack_finish = true;
    }
    if (m_weapon != null) {
      m_weapon.GetComponent<Collider>().enabled = false;
    }
    if (animator.TryGetComponent(out PlayerAnimationEvents animation_events)) {
      animation_events.ResetTrail();
      animation_events.StopSkillEffects(skill_id);
    }
  }
}
