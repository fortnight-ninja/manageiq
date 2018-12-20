class ManageIQ::Providers::EmbeddedAnsible::AutomationManager::OrangeCredential < ManageIQ::Providers::EmbeddedAnsible::AutomationManager::CloudCredential
  include ManageIQ::Providers::AnsibleTower::Shared::AutomationManager::OrangeCredential

  def self.display_name(number = 1)
    n_('Credential (Orange)', 'Credentials (Orange)', number)
  end
end
