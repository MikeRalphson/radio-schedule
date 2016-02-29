from cosmosTroposphere import CosmosTemplate
t = CosmosTemplate(
  project_name="radio",
  component_name="radio-schedule",
  description="Radio Schedule Tool"
)
print(t.to_json())
