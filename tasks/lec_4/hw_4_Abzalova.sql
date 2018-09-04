--2
create or replace function check_access_comm(ip_addr in incb_commutator.ip_address%type,
                                            v_community in incb_commutator.v_community_read%type, /*или составной тип данных?*/
                                            b_mode_write in number)  
return number is 
commutator_count number;
  
begin

    begin
        select ic.id_commutator
        into commutator_count
        from incb_commutator ic
        where ic.ip_address = ip_addr 
        and ic.b_deleted = 0;
       
        exception 
        when no_data_found then
            raise_application_error(-20020, 'Коммутатора с таким IP не существует');
    end; 
  
  select count(*)
  into commutator_count
  from incb_commutator ic
  where ic.ip_address = ip_addr
         and ic.b_deleted = 0
         and v_community = (case b_mode_write
            when 1 then 
            ic.v_community_write 
            when 0 then
            ic.v_community_read 
            end); 
         

     
return (case commutator_count
        when commutator_count > 0 then  1
        when commutator_count =0 then  0
        end);  

end;

--3
create or replace function get_remote_id(ip_commut in incb_commutator.ip_commutator%type)

return varchar2 is 
commutator_count number;
return_value varchar2;
  
begin

 begin 
    select ic.id_commutator
    into commutator_count
    from incb_commutator ic 
    where ic.id_commutator = ip_commut
     and ic.b_deleted = 0;

    exception 
    when no_data_found then
        raise_application_error(-20020, 'Коммутатора с таким IP не существует');
 end; 

    select ( case ic.b_need_convert_hex
            when 1 then ic.remote_id_hex
            when 0 then (case ic.remote_id
                         when null then Raise except_20021
                         else ic.remote_id
                         end)
            end)
    into return_value
    from incb_commutator ic 
    where ic.id_commutator = ip_commut
    and ic.b_deleted = 0;
  
    exception  
    when except_20021 then
    raise_application_error(-20021, 'Идентификатор коммутатора в hex формате пуст');
  return return_value;
end;

--4

CREATE OR REPLACE procedure check_and_del_data ( b_force_delete in incb_commutator.ip_commutator%type) is

begin

/*1.создать коллекцию для заполнения таблицы incb_commutator*/
    type table_incb_commut is table of incb_commutator%rowtype

/*2.заполнить коллекци рандомными числами*/  

begin
for i 
end
/*3.заполнить таблицу incb_commutator значениями из коллекции*/
    
    insert into incb_commutator (id_commutator, ip_address, id_commutator_type, v_description, b_deleted,
    v_mac_addrecc, v_community_read, v_community_write, remote_id, b_need_convert_hex, remote_id_hex)
    select (val1, val2, val3, val4, val5, val6, val7, val8, val9, val10, val11)
    from table_incb_commut
    
    
/*создать коллекцию некорректных кодов коммутаторов*/

/*если b_force_delete = 1, то найти некорректные коды в табл incb_commutator, вернуть их в коллекцию и удалить их из табл;
если b_force_delete = 0, то найти некорректные коды в табл incb_commutator и вернуть их в коллекцию*/ 


end;