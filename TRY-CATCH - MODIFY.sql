  SET NOCOUNT ON

  -- Блок объявления переменных располагается ДО первого "BEGIN TRY"
  DECLARE
    @TranCount        Int,
    @DeadLockRetries  TinyInt   = 5,
    @DeadLockDelay    DateTime  = '00:00:00.500',
    @SavePoint        SysName   = 'TEST_TRAN',
    @Retry            TinyInt,
    @ErrorNumber      Int

  BEGIN TRY
    -- Блок, не защищаемый от ДедЛока

    ---
    ---
    ---

    -- Конец Блока, не защищаемого от ДедЛока

    -- Создаем точку возврата для транзакции
    SET @TranCount = @@TRANCOUNT
    SET @Retry = CASE WHEN @TranCount = 0 THEN @DeadLockRetries ELSE 1 END

    WHILE (@Retry > 0)
    BEGIN TRY
      IF @TranCount > 0
        SAVE TRAN @SavePoint
      ELSE
        BEGIN TRAN

      -- Блок с защитой от ДедЛока

      ---
      ---
      ---

      -- Конец Блока защиты от ДедЛока

      WHILE @@TRANCOUNT > @TranCount COMMIT TRAN
      SET @Retry = 0
    END TRY
    BEGIN CATCH
      SET @ErrorNumber = ERROR_NUMBER()
      IF @ErrorNumber IN (1205, 51205) BEGIN -- DEAD LOCK OR USER DEAD LOCK
        SET @ErrorNumber = 51205
        SET @Retry = @Retry - 1
      END ELSE
        SET @Retry = 0

      IF XACT_STATE() = -1 OR @@TRANCOUNT > @TranCount
        ROLLBACK TRAN
      ELSE IF XACT_STATE() = 1 AND @@TRANCOUNT = @TranCount
        ROLLBACK TRAN @SavePoint

      IF @@TRANCOUNT = 0 OR @Retry = 0
        EXEC [System].[ReRaise Error] @ErrorNumber = @ErrorNumber, @ProcedureId = @@PROCID
      ELSE
        -- Задержка пол секунды при ДедЛоке
        WAITFOR DELAY @DeadLockDelay
    END CATCH

    -- Важно! Лишь код возврата "1" означает что процедура успешно выполнилась.
    RETURN 1
  END TRY
  BEGIN CATCH
    EXEC [System].[ReRaise Error] @ProcedureId = @@PROCID
  END CATCH
GO
