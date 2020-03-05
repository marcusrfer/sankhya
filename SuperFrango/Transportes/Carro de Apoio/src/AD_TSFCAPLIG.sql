-- Create table
create table AD_TSFCAPLIG
(
  nuap     NUMBER(10),
  nuaporig NUMBER(10)
)
tablespace TBS_DADOS_A
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  );
-- Create/Recreate primary, unique and foreign key constraints 
alter table AD_TSFCAPLIG
  add constraint AD_FK_48AD61582ABD9EFF60B88 foreign key (NUAPORIG)
  references AD_TSFCAP (NUAP);
