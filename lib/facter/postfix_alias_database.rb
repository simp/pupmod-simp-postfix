# frozen_string_literal: true

Facter.add(:postfix_alias_database) do
  confine { Facter::Core::Execution.which('postconf') }

  setcode do
    Facter::Core::Execution.execute('postconf -h alias_database').strip
  rescue
    nil
  end
end
