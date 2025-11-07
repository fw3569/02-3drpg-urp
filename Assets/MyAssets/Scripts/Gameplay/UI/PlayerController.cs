using System.Collections.Generic;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.InputSystem;

[RequireComponent(typeof(Animator))]
public class PlayerController : MonoBehaviour {
  private Animator m_animator;
  private InputAction m_move_action;
  [SerializeField] private Vector2 m_move_acceleration = new(5.0f, 5.0f);
  private InputAction m_look_action;
  [SerializeField] private float m_camera_speed = 0.1f;
  private Vector2 look_forward = new(0.0f, 0.0f);
  private InputAction m_attack_action;
  private float m_attack_active_time = 0.0f;
  private InputAction m_jump_action;
  private float m_jump_active_time = 0.0f;
  private InputAction m_sprint_action;
  [SerializeField] private float m_input_active_duration = 0.5f;
  [SerializeField] private List<Skill> m_skills = new();

  void Awake() {
    m_animator = GetComponent<Animator>();
    m_move_action = InputSystem.actions.FindAction("Move");
    m_look_action = InputSystem.actions.FindAction("Look");
    m_attack_action = InputSystem.actions.FindAction("Attack");
    m_jump_action = InputSystem.actions.FindAction("Jump");
    m_sprint_action = InputSystem.actions.FindAction("Sprint");
    Dictionary<string, SkillCDTimer> cd_timers = new();
    foreach (Skill skill in m_skills) {
      skill.skill_input_action = InputSystem.actions.FindAction(skill.input_action_name);
      skill.cd_timer.animator = m_animator;
      skill.cd_timer.cd_time = skill.cd_time;
      skill.cd_timer.animator_enable_name = skill.animator_enable_name;
      cd_timers.Add(skill.skill_id, skill.cd_timer);
    }
    SkillCoolDownBehaviour[] cd_behaviours = m_animator.GetBehaviours<SkillCoolDownBehaviour>();
    foreach (var behaviour in cd_behaviours) {
      if (cd_timers.ContainsKey(behaviour.skill_id)) {
        behaviour.cd_timer = cd_timers[behaviour.skill_id];
      }
    }
  }

  void Update() {
    Vector2 input_vector = m_move_action.ReadValue<Vector2>();
    Vector3 camera_front = Camera.main.transform.forward;
    camera_front.y = 0.0f;
    camera_front.Normalize();
    Vector3 camera_right = Vector3.Cross(Vector3.up, camera_front);
    Vector3 move_vector = camera_front * input_vector.y + camera_right * input_vector.x;
    Vector3 modle_front = transform.forward;
    modle_front.y = 0.0f;
    modle_front.Normalize();
    Vector3 modle_right = Vector3.Cross(Vector3.up, modle_front);
    float input_fb = Vector3.Dot(move_vector, modle_front);
    if (m_sprint_action.IsPressed()) {
      input_fb *= 1.43f;
    }
    float input_lr = Vector3.Dot(move_vector, modle_right);
    float velocity_fb = m_animator.GetFloat("velocity_fb");
    float velocity_lr = m_animator.GetFloat("velocity_lr");
    Vector2 velocity_diff = new(input_lr - velocity_lr, input_fb - velocity_fb);
    if (math.abs(velocity_diff.x) > m_move_acceleration.x * Time.deltaTime) {
      velocity_diff.x = math.sign(velocity_diff.x) * m_move_acceleration.x * Time.deltaTime;
    }
    if (math.abs(velocity_diff.y) > m_move_acceleration.y * Time.deltaTime) {
      velocity_diff.y = math.sign(velocity_diff.y) * m_move_acceleration.y * Time.deltaTime;
    }
    velocity_fb += velocity_diff.y;
    velocity_lr += velocity_diff.x;
    m_animator.SetFloat("velocity_fb", velocity_fb);
    m_animator.SetFloat("velocity_lr", velocity_lr);
    if (m_attack_action.WasPressedThisFrame()) {
      m_animator.SetTrigger("Attack");
      m_attack_active_time = Time.time + m_input_active_duration;
    } else if (m_attack_active_time != 0 && m_attack_active_time <= Time.time) {
      m_attack_active_time = 0.0f;
      m_animator.ResetTrigger("Attack");
    }
    if (m_jump_action.WasPressedThisFrame()) {
      m_animator.SetTrigger("Jump");
      m_jump_active_time = Time.time + m_input_active_duration;
    } else if (m_jump_active_time != 0 && m_jump_active_time <= Time.time) {
      m_jump_active_time = 0.0f;
      m_animator.ResetTrigger("Jump");
    }
    foreach (Skill skill in m_skills) {
      if (skill.skill_input_action.WasPressedThisFrame()) {
        m_animator.SetTrigger(skill.animator_trigger_name);
        skill.input_active_time = Time.time + m_input_active_duration;
      } else if (skill.input_active_time != 0 && skill.input_active_time <= Time.time) {
        skill.input_active_time = 0;
        m_animator.ResetTrigger(skill.animator_trigger_name);
      }
    }
  }
  void LateUpdate() {
    look_forward += m_look_action.ReadValue<Vector2>() * m_camera_speed;
    Camera.main.transform.parent.rotation = Quaternion.Euler(-look_forward.y, look_forward.x, 0.0f);
  }
}
