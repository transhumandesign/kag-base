void onRender(CRules@ this)
{
    if (!ImGui::Begin("Shadowmap")) {
        ImGui::End();
        return;
    }

	this.shadowmap_config.ao_gamma = ImGui::SliderFloat("ao_gamma", this.shadowmap_config.ao_gamma, -1.0f, 2.0f, 1.0f);
	this.shadowmap_config.ao_scale = ImGui::SliderFloat("ao_scale", this.shadowmap_config.ao_scale, 0.0f, 1.0f, 1.0f);

	this.shadowmap_config.back_gamma = ImGui::SliderFloat("back_gamma", this.shadowmap_config.back_gamma, -1.0f, 2.0f, 1.0f);
	this.shadowmap_config.back_scale = ImGui::SliderFloat("back_scale", this.shadowmap_config.back_scale, 0.0f, 1.0f, 1.0f);

	this.shadowmap_config.front_gamma = ImGui::SliderFloat("front_gamma", this.shadowmap_config.front_gamma, -1.0f, 2.0f, 1.0f);
	this.shadowmap_config.front_scale = ImGui::SliderFloat("front_scale", this.shadowmap_config.front_scale, 0.0f, 1.0f, 1.0f);

	ImGui::End();
}