using System;
using UnityEngine;
using UnityEngine.InputSystem;

[Serializable]
public class Skill {
  public string skill_id;
  public SkillCDTimer cd_timer;
  public float cd_time;
  public string input_action_name;
  [HideInInspector] public InputAction skill_input_action;
  [HideInInspector] public float input_active_time;
  public string animator_trigger_name;
  public string animator_enable_name;
}
