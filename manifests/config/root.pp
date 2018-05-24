# root user postfix Configuration class called from postfix::config.
#
class postfix::config::root {
  assert_private()

  # Since we're using Maildir's set up root's mail alias to be mutt and set
  # up the mutt configuration to read the Maildir in root's home directory.
  simp_file_line { '/root/.bashrc':
    path       => '/root/.bashrc',
    line       => 'alias mail="mutt"',
    deconflict => true
  }

  $_muttrc_content = @(MUTTRC)
    set mbox_type="Maildir"
    set folder="~/Maildir"
    set mask="!^\\.[^.]"
    set mbox="~/Maildir"
    set record="+.Sent"
    set postponed="+.Drafts"
    set spoolfile="/var/spool/mail/root"
    mailboxes `echo -n "+ "; find ~/Maildir -type d -name ".*" -printf "+\'%f\' "`
    | MUTTRC

  file { '/root/.muttrc':
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    replace => false,
    content => $_muttrc_content
  }

}
