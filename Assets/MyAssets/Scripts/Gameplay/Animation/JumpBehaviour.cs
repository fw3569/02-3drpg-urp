using UnityEngine;

public class JumpBehaviour : StateMachineBehaviour {
  [SerializeField] private float m_jump_velocity = 5.0f;
  Vector3 m_move_velocity = new(0.0f, 0.0f);
  [SerializeField] private float m_f_speed = 0.0f;
  override public void OnStateEnter(Animator animator, AnimatorStateInfo stateInfo, int layerIndex) {
    float velocity_fb = animator.GetFloat("velocity_fb");
    Vector3 modle_front = animator.transform.forward;
    modle_front.y = 0.0f;
    modle_front.Normalize();
    m_move_velocity = m_f_speed * velocity_fb * modle_front;
    Rigidbody rigidbody = animator.GetComponent<Rigidbody>();
    rigidbody.AddForce(new Vector3(0.0f, m_jump_velocity, 0.0f), ForceMode.VelocityChange);
  }
  override public void OnStateUpdate(Animator animator, AnimatorStateInfo stateInfo, int layerIndex) {
    animator.transform.position += m_move_velocity * Time.deltaTime;
  }
}
