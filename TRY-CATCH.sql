  SET NOCOUNT ON

  BEGIN TRY
    -- Блок, не защищаемый от ДедЛока

    ---
    ---
    ---

    -- Важно! Лишь код возврата "1" означает что процедура успешно выполнилась.
    RETURN 1
  END TRY
  BEGIN CATCH
    EXEC [System].[ReRaise Error] @ProcedureId = @@PROCID
  END CATCH
GO
