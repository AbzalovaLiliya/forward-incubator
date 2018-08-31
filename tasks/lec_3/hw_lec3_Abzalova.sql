--1
CREATE OR REPLACE procedure saveSigners(pV_FIO      in scd_signers.v_fio%TYPE := 'Abdullin',
                                        pID_MANAGER in scd_signers.ID_MANAGER%TYPE :=202002,
                                        pACTION     in number :=1) is

user_count number;
BEGIN

    begin
      SELECT cu.id_user 
      INTO user_count 
      FROM ci_users cu
      WHERE cu.id_user = pID_MANAGER;
    EXCEPTION
        WHEN no_data_found THEN
        raise_application_error (-20020,'Пользователь не найден');
   
    CASE
        WHEN pACTION = 1 THEN
            INSERT INTO scd_signers 
            (v_fio, id_manager)
            VALUES
            (pV_FIO, pID_MANAGER);
        WHEN pACTION = 2 THEN
            UPDATE scd_signers 
            SET v_fio = pV_FIO
            WHERE id_manager = pID_MANAGER;
        WHEN pACTION = 3 THEN
            DELETE FROM scd_signers WHERE id_manager = pID_MANAGER;
    END CASE;
  
/*EXCEPTION
    raise_application_error(-1,
                            'Пользователь заведен в справочнике');*/
 end;
end;

--2
CREATE OR REPLACE FUNCTION getdecoder_1(id_equip_ki IN scd_equip_kits.id_equip_kits_inst%TYPE:=222)
  
  RETURN VARCHAR2 IS
  return_value VARCHAR2(100);
  
  BEGIN

  SELECT (case sc.b_agency
            when 1 then sek.v_cas_id
            when 0 then sek.v_ext_ident
            end)
    INTO return_value
    FROM scd_contracts sc
    JOIN scd_equip_kits sek
      ON sek.id_contract_inst = sc.id_contract_inst
     AND sek.dt_start <= current_timestamp
     AND sek.dt_stop >= current_timestamp
   WHERE sek.id_equip_kits_inst = id_equip_ki ;
   
    EXCEPTION 
    WHEN no_data_found THEN
        raise_application_error(-2, 'Оборудование не найдено');
      
   RETURN return_value;  
  END;

--3
create or replace procedure getEquip(pID_EQUIP_KITS_INST in scd_equip_kits.id_equip_kits_inst%TYPE default null,
                                     dwr                 out sys_refcursor) is

begin

    
      open dwr for
        select distinct fc.v_long_title,
                        cu.v_username,
                        fc.v_ext_ident,
                        sekt.v_name,
                        getDecoder(pID_EQUIP_KITS_INST) as decoder_num
          
        from
            scd_equip_kits sek
               join scd_equipment_kits_type sekt on sekt.id_equip_kits_type = sek.id_equip_kits_type
                                    and sekt.dt_start <= current_timestamp
                                    and sekt.dt_stop > current_timestamp 
                join fw_contracts fc on fc.id_contract_inst = sek.id_contract_inst
                                        and fc.dt_start <= current_timestamp
                                        and fc.dt_stop > current_timestamp
                                        and fc.v_status = 'A'
                    join ci_users cu on cu.id_user = fc.id_client_inst
                                            and cu.v_status = 'A' 
                        join fw_clients fcli on fcli.id_client_inst = cu.id_user 
                                                and fcli.dt_start <= current_timestamp
                                                and fcli.dt_stop > current_timestamp
                    
           where sek.id_equip_kits_inst = pID_EQUIP_KITS_INST or pID_EQUIP_KITS_INST is null
                    and sek.dt_start <= current_timestamp
                    and sek.dt_stop > current_timestamp;
           
    exception 
       when no_data_found then 
        raise_application_error(-1, 'Оборудование не найдено');

end;            
        
--4
create or replace procedure checkstatus is

client_name    fw_clients.v_long_title%TYPE;
ident_contract fw_contracts.v_ext_ident%TYPE;
id_equip_ki    scd_equip_kits.id_equip_kits_inst%TYPE;
status_name    scd_equipment_status.v_name%TYPE;
agency         scd_contracts.b_agency%TYPE;

cursor checkstatus_cursor is
    select 
        sek.id_equip_kits_inst,
        fcli.v_long_title,
        fc.v_ext_ident,
        sc.b_agency,
        ses.v_name
               
       from scd_equip_kits sek
         join scd_contracts sc on sc.id_contract_inst = sek.id_contract_inst 
            join fw_contracts fc on fc.id_contract_inst = sek.id_contract_inst 
                                    and fc.dt_start <= current_timestamp
                                    and fc.dt_stop > current_timestamp
                                    and fc.v_status = 'A'
           
                join ci_users cu on cu.id_user = fc.id_client_inst
                                        and cu.v_status = 'A' 
                    join fw_clients fcli on fcli.id_client_inst = cu.id_user
                                                    and fcli.dt_start <= current_timestamp
                                                    and fcli.dt_stop > current_timestamp
                         join scd_equipment_status ses on ses.id_equipment_status = sek.id_status
                                                         and ses.b_deleted = 0
                                                         and ses.v_name != 'Продано'                                       
                                       
       where sek.id_dealer_client is not null
                and sek.dt_start <= current_timestamp
                and sek.dt_stop > current_timestamp
     
     for update of ses.v_name;             
       

begin
    open checkstatus_cursor;
    loop
        fetch checkstatus_cursor into id_equip_ki, client_name, ident_contract, agency, status_name;
        exit when checkstatus_cursor%notfound;
        update scd_equipment_status ses
        set ses.v_name = 'Продано'
        where current of checkstatus_cursor;
        
            dbms_output.put_line('Для оборудования '||id_equip_ki||' дилера '|| client_name|| ' с контрактом '|| ident_contract|| ', '||
                                            case agency
                                            when 1 then 'являющегося агентской сетью был проставлен статус Продано.'
                                            else  'неявляющегося агентской сетью был проставлен статус Продано.'
                                            end);



    end loop;

close checkstatus_cursor;
end;      
     