SQLCMD -S HPFabiano\SQL2012 -E -I -i "Setup BancoDados.sql"
SQLCMD -S HPFabiano\SQL2012 -E -I -i "dbo.proc_InserePessoaFisica.sql"