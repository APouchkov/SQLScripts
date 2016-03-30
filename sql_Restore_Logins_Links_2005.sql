declare @name varchar(99)
LB_U:

Select top 1 @name=name From sysusers Where len(sid)>10 and sid<>(Select sid From master.dbo.syslogins Where loginname=sysusers.name)
if @@rowcount=1 begin
  print @name
	exec sp_change_users_login @Action = 'Update_One', @UserNamePattern = @name, @LoginName = @name
	--exec sp_adduser @name
	goto LB_U
end


-- Single Repair
--	exec sp_change_users_login @Action = 'Update_One', @UserNamePattern = 'md', @LoginName = 'md'

