using UnityEngine;
using UnityEngine.UI;

public class SkillCDTimer : MonoBehaviour {
  [HideInInspector] public Animator animator;
  [SerializeField] private Image m_mask;
  [HideInInspector] public float cd_time;
  [HideInInspector] private float m_remain_time = 0;
  [HideInInspector] public string animator_enable_name;
  void Update() {
    if (animator == null) {
      return;
    }
    if (m_remain_time > 0) {
      m_remain_time -= Time.deltaTime;
      if (m_remain_time <= 0) {
        ResetTimer();
      }
      m_mask.fillAmount = m_remain_time / cd_time;
    }
  }
  public void ResetTimer() {
    m_remain_time = 0;
    animator.SetBool(animator_enable_name, true);
  }
  public void SetTimer() {
    m_remain_time = cd_time;
    animator.SetBool(animator_enable_name, false);
  }
}
