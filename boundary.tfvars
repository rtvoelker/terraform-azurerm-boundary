#database_admins = {
#  "Roland" = {
#    user_principal_name = "roland.voelker@gmx.de"
#    display_name        = "Roland Voelker"
#    mail_nickname       = "roland.voelker"
#  },
#}
#
#operators = (
#{
#  user_principal_name = "principal name"
#  display_name = "Display Name"
#  mail_nickname = "Mail Nickname"
#}
#)

#device_status_subscriptions = {
#  "" = {
#    message_retention          = 3
#    connection-state-condition = "(NOT IS_DEFINED($connectionModuleId)) OR ($connectionModuleId = '') OR IS_NULL($connectionModuleId)"
#    twin-change-condition      = "$connectionModuleId != '$edgeHub'"
#  },
#  "-dev" = {
#    message_retention          = 1
#    connection-state-condition = "$connectionDeviceId = 'symdemodev' AND ((NOT IS_DEFINED($connectionModuleId)) OR ($connectionModuleId = '') OR IS_NULL($connectionModuleId))"
#    twin-change-condition      = "$connectionDeviceId = 'symdemodev' AND $connectionModuleId != '$edgeHub'"
#  }
#}