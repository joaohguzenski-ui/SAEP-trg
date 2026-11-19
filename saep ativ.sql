
create table colaboradores (
   id serial primary key,
   nome varchar(100) not null,
   email varchar(100) unique not null,
   cpf_criptografado bytea not null,
   ativo boolean default true,
   data_cadastro timestamp default current_timestamp
   );
   create table categorias (
      id serial primary key,
	  nome varchar(50) unique not null
	  );

create table tarefas (
id serial primary key,
categoria_id int references categorias(id),
colaborador_id int references colaboradores(id),
titulo varchar(150) not null,
descricao text,
data_agendamento date not null,
status varchar(20) default 'Pendente' check (status in ('Pendente','Em Andamento', 'Concluida','Cancelada')),
data_criacao timestamp default current_timestamp
)

create table historico_tarefas(
    id serial primary key,
    tarefa_id int references tarefas(id) on delete cascade,
    observacao varchar(200) not null,
    data_alteracao timestamp default current_timestamp
);



insert into colaboradores (nome,email,cpf_criptografado,senha_hash) values
('Sonia Barbara','sonia@consultoria.com',pgp_sys_encryt('11122223333', 'chave_lgpd'), encode(digest('senha123','sha256'), 'hex')),
('Jonas Silva','jonas@consultoria.com',pgp_sys_encryt('09777999887', 'chave_lgpd'), encode(digest('admin123','sha256'), 'hex')),
('Camila Santos','camila@consultoria.com',pgp_sys_encryt('6267383992', 'chave_lgpd'), encode(digest('mudar123','sha256'), 'hex'));

insert into categorias (nome) values
('Desenvolvimento'),
('Consultoria LGPD'),
('gestão de Projetos');

insert into tarefas (categoria_id, colaborador_id,titulo,descricao, data_agendamento, status) values
(1,1 ,'Modelagem  do Banco de Dados', 'Criar DER e scripts DDL/DML para o cliente', current_date + interval '2 days','Em Andamento'),
(2,2 ,'Auditoria de Seguranca LGPD','Mapear dados sensíveis e implementar criptografia' current_date + interval '5 days','Pendente'),
(3,3 ,'Reunião de  Alinhamento com o Cliente', 'Apresentar cronograma do projeto',current_date + interval '1 day','pendente');

create or replace function  fn_authenticador_usuario(
      p_email varchar,
	  p_senha varchar
)
returns table (
      authenticado boolean,
	  colaborador_id int,
	  nome varchar,
	  mensagem varchar
) as $$
declare
     v_hash varchar(64);
	 v_id int;
	 v_nome varchar(100);
	 v_ativo boolean;
begin 
 v_hash :=encode(digest(p_senha, 'sha256'), 'hex');

 select id.c.nome, ativo into v_id,v_nome, v_ativo
 from colaboradores c
 where c.email = p_email and senha_hash = v_hash;

 if v_id is null then
    return query select false, null ::int, null::varchar, 'Usuário ou senha inválidos'::varchar;
	elsif not v_ativo then
	return query select false,null::int,null::varchar,'Acesso Negado :Colaborador inaivo':: Varchar;
	else
	return query select true, v_id, v_nome, 'Authenticação realizada com sucesso!' ::Varchar;
	end if;
end;
$$ language plpgsql;

create or replace view vw_painel_principal as 
select
  t.id as tarefa_id,
  c.nome as colaborador_responsavel, 
  cat.nome as categori,
  t.titulo as tarefa,
  t.data_agendamento,
  t.status
from tarefas t
join colaboradores c on t.colaborador_id = c.id
join categorias cat on t.categoria_id = cat.id;

create or replace function fn_buscar_colaboradores(p_termo varchar)
returns table (
      id int,
	  nome varchar,
	  email varchar,
	  cpf_descriptografado text,
	  ativo boolean
) as $$
begin
    return query
	select
	    c.id,
		c.nome,
		c.email,
		pgp_sys_decrypt(c.cpf_criptografado, 'chave_lgpd')::text,
		c.ativo
	from colaboradores c
	where lower(c.nome) like lower('%'|| p_termo || '%')
	or lower(c.email) like lower('%' || p_termo || '%');
	end;
	$$ language plpgsql;

create or replace function fn_trg_validar_e_logar_tarefa()
returns trigger as $$
declare
     v_ativo boolean;
begin

     selelct ativo into v_ativo from colaboradores where id = new.colaborador_id

	 if v_ativo is null or not v_ativo then
	 raise exception 'Não é possível atribuir tarefas a um colaborador inativo ou inexsistente.';
	 end if;

	 return new;
 end;
$$ language plpgsql;

create trigger trg_validar_tarefa
before insert on tarefas
for each row
execute function fn_trg_validar_e_logar_tarefa();

create or replace function fn_trg_historico_tarefa()
returns trigger as $$
begin
     insert into historio_tarefas (tarefa_id , observacao)
	 values (new.id,'tarefa criada e atribu[ida com status '|| new.status);
end;
$$ language plpgsql;

create trigger trg_log_historico_tarefa
after insert on tarefas
for each row
execute functon fn_trg_historico_tarefa();

create or replace view vw_cronograma_prazos as 
select
     t.id as tarefa_id,
     t.titulo as tarefa,
     c.nome as colaborador_responsavel,
     t.data_agendamento,
     (data_agendamento - current_date) as dias_restantes,
     t.status
   from tarefas
   join colaboradores c on t.colaborador_id = c.id
   order by t.data_agendamento asc;

   --approved

   select * from fn_authenticar_usuario('sonia@consultoria.com','senha123');

      select * from fn_authenticar_usuario('jonas@consultoria.com','admin123');

         select * from fn_authenticar_usuario('camila@consultoria.com','mudar123');

         --error

          select * from fn_authenticar_usuario('sonia@consultoria.com','Tente denovo!');

      select * from fn_authenticar_usuario('jonas@consultoria.com','Tente denovo!');

         select * from fn_authenticar_usuario('camila@consultoria.com','Tente denovo!');



   select * from vw_painel_principal;

   select * from vw_cronograma_prazos;