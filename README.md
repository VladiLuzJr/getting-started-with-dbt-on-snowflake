# Plataforma dbt + Snowflake orientada a domínios

## Visão geral

Este repositório entrega um template completo para construir uma plataforma de dados em Snowflake usando dbt, seguindo a divisão de zonas RAW → STANDARD → REFINED → CONSUMPTION. Toda a modelagem foi organizada por domínio (`tastybytes`) e está pronta para receber novos produtos de dados repetindo o mesmo padrão.

## Pré-requisitos

1. **Conta Snowflake** com os bancos e esquemas (DEV/PRD) já criados:
   - DEV_RAW.TASTYBYTES, DEV_STANDARD.TASTYBYTES, DEV_REFINED.TASTYBYTES, DEV_CONSUMPTION.TASTYBYTES
   - PRD_RAW.TASTYBYTES, PRD_STANDARD.TASTYBYTES, PRD_REFINED.TASTYBYTES, PRD_CONSUMPTION.TASTYBYTES
2. **Roles e warehouses**
   - Role `DEV_PLATFORM_ROLE` com acesso total aos bancos DEV\_* e aos warehouses:
     - `DEV_RAW_WH`, `DEV_STANDARD_WH`, `DEV_REFINED_WH`, `DEV_CONSUMPTION_WH`
   - Role `PRD_PLATFORM_ROLE` com acesso total aos bancos PRD\_* e aos warehouses:
     - `PRD_RAW_WH`, `PRD_STANDARD_WH`, `PRD_REFINED_WH`, `PRD_CONSUMPTION_WH`
3. **dbt Core ≥ 1.7** instalado localmente (via pip ou homebrew) e Python 3.10+.
4. **SnowSQL opcional** apenas se quiser validar conexão fora do dbt.

## Variáveis de ambiente

Configure as credenciais antes de executar qualquer comando:

```bash
export DEV_SNOWFLAKE_ACCOUNT="meu_account"
export DEV_SNOWFLAKE_USER="meu_usuario_dev"
export DEV_SNOWFLAKE_PASSWORD="senha_dev"

export PRD_SNOWFLAKE_ACCOUNT="meu_account"
export PRD_SNOWFLAKE_USER="meu_usuario_prd"
export PRD_SNOWFLAKE_PASSWORD="senha_prd"
```

Esses valores alimentam `profiles.yml` e permitem alternar entre `dev` e `prod` somente com `--target`.

## Estrutura do projeto

```
tasty_bytes_dbt_demo/
  dbt_project.yml                # Configura mapeamento de banco/esquema por zona
  profiles.yml                   # Perfis Snowflake (dev/prod)
  packages.yml                   # Dependências dbt (ex.: dbt_utils)
  macros/
    standardize.sql              # Macro para deduplicação padrão (STANDARD)
    generate_schema_name.sql     # Ajustes de nomenclatura
  models/
    raw/tastybytes/              # Modelos RAW => views em DEV_RAW.TASTYBYTES
    standard/tastybytes/         # Modelos STANDARD => tables em DEV_STANDARD.TASTYBYTES
    refined/tastybytes/          # Modelos REFINED => tables em DEV_REFINED.TASTYBYTES
    consumption/tastybytes/      # Secure views em DEV_CONSUMPTION.TASTYBYTES

Cada camada já aponta para um warehouse dedicado (`DEV_RAW_WH`, `DEV_STANDARD_WH`, etc.), então não é necessário alterar o profile para controlar consumo de recursos.
  tests/                         # (Opcional) testes adicionais
```

As tags configuradas permitem seleções como:
- `dbt run --select tag:zone:raw`
- `dbt run --select tag:zone:refined`
- `dbt run --select domain:tastybytes`

## Macro de deduplicação STANDARD

`macros/standardize.sql` aplica `row_number()` particionando pelo ID e ordenando por colunas do tipo `updated_at`/`modified_at`. Basta criar um modelo no STANDARD layer com:

```jinja
{{ deduplicate_standard('raw_pos_order_detail', 'ORDER_DETAIL_ID') }}
```

## Passo a passo de execução (ambiente dev)

1. **Instalar dependências (se houver)**  
   ```bash
   cd tasty_bytes_dbt_demo
   dbt deps
   ```

2. **Validar perfil/conexão**  
   ```bash
   dbt debug --target dev
   ```

3. **Criar RAW → STANDARD → REFINED**  
   ```bash
   dbt run --target dev --select tag:zone:raw+tag:zone:standard+tag:zone:refined
   ```

4. **Criar views de consumo (secure)**  
   ```bash
   dbt run --target dev --select tag:zone:consumption
   ```

5. **Executar testes**  
   ```bash
   dbt test --target dev --select tag:zone:standard+tag:zone:refined
   ```

6. **Listar modelos por domínio ou zona (opcional)**  
   ```bash
   dbt ls --select domain:tastybytes
   dbt ls --select tag:zone:refined
   ```

## Promoção para produção

1. Ajuste as variáveis `PRD_*` no ambiente onde o dbt será executado.
2. Valide a conexão:
   ```bash
   dbt debug --target prod
   ```
3. Rode o mesmo pipeline:
   ```bash
   dbt run  --target prod --select tag:zone:raw+tag:zone:standard+tag:zone:refined
   dbt run  --target prod --select tag:zone:consumption
   dbt test --target prod --select tag:zone:standard+tag:zone:refined
   ```

## Dicas para expandir para novos domínios

1. Copie a pasta `models/raw/tastybytes` para `models/raw/<novo_dominio>`.
2. Repita o processo para `standard`, `refined` e `consumption`.
3. Atualize `dbt_project.yml` adicionando a nova chave (por exemplo, `models.raw.novo_dominio` com tag `domain:<nome>`).
4. Crie `sources.yml` específicos apontando para os esquemas RAW do novo domínio.
5. Utilize o macro `deduplicate_standard` e mantenha os testes de unicidade.

Com esse fluxo você garante consistência entre os domínios, facilita execuções seletivas (`dbt run --select domain:finance`) e mantém o alinhamento com a arquitetura DEV_RAW/DEV_STANDARD/DEV_REFINED/DEV_CONSUMPTION.

## Suporte

Em caso de dúvidas:
- Verifique os logs em `target/run_results.json`.
- Consulte a documentação oficial: [docs.getdbt.com](https://docs.getdbt.com/).
- Abra uma issue neste repositório descrevendo ambiente, comando e stack trace.

Agora é só configurar as variáveis, executar os comandos e o pipeline completo estará disponível imediatamente após o clone. Bons dados! 💙
