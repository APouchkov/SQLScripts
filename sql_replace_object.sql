EXEC [SQL].[Rename Object?Script]
  @source_object  = '[BackOffice].[Dic:Deals:Types]',
  @target_object  = '[BackOffice].[Deals->Types$]',
  @create_synonym = 0

 --EXEC [SQL].[Replace Metadata]
 --  @Object_OLD  = 'mnRecordActionClick',
 --  @Object_NEW  = 'DataSourceRecordActionClick',
 --  @Replacement = 'RND',
 --  @Execute     = 0


/*
ALTER ROLE Group_BackOffice WITH NAME = [Group_Firm1#BackOffice]
#O
UPDATE [dbo].[cfPseudoRules] SET [RuleName] = 'Group_Firm1#BackOffice' WHERE [RuleName] = 'Group_BackOffice'
UPDATE [dbo].[cfUserRules] SET RuleObject = 'Group_Firm1#BackOffice' WHERE RuleObject = 'Group_BackOffice'
#O
EXEC [SQL].[Access] 'Group_Firm1#BackOffice'
*/