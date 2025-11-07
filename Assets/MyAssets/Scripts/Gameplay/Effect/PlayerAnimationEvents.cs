using System.Collections.Generic;
using UnityEngine;

public class PlayerAnimationEvents : MonoBehaviour {
  public WeaponTrail weapon_trail;
  public List<ParticleSystem> skill1_effects;
  public List<ParticleSystem> skill2_effects;
  public void SetTrail() {
    weapon_trail.generating = true;
  }
  public void ResetTrail() {
    weapon_trail.generating = false;
  }
  public void PlaySkill1Effects() {
    foreach (ParticleSystem effect in skill1_effects) {
      effect.transform.SetPositionAndRotation(transform.position + transform.forward * 1.7f, transform.rotation);
      effect.Play();
    }
  }
  public void PlaySkill2Effects() {
    foreach (ParticleSystem effect in skill2_effects) {
      effect.Play();
    }
  }
  public void StopSkill2Effects() {
    foreach (ParticleSystem effect in skill2_effects) {
      effect.Stop();
    }
  }
  public void StopSkillEffects(string skill_id) {
    switch (skill_id) {
      case "Skill1": break;
      case "Skill2":
        StopSkill2Effects();
        break;
      default: break;
    }
  }
}