--1

CREATE OR REPLACE procedure saveSigners(pV_FIO      in scd_signers.v_fio%TYPE,
                                        pID_MANAGER in scd_signers.ID_MANAGER%TYPE,
                                        pACTION     in number) is

BEGIN
  SELECT ss.id_manager 
  INTO pID_MANAGER 
  FROM scd_signers ss
  WHERE ci_users.id_user = pID_MANAGER;

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
            DELETE FROM scd_signers WHERE pID_MANAGER = id_manager;
    END CASE;
  
EXCEPTION
    WHEN no_data_found THEN
    raise_application_error (-20020,'ѕользователь не найден');
    WHEN OTHERS THEN
    raise_application_error(??,
                            'ѕользователь заведен в справочнике');
END;


--2

--1var
CREATE OR REPLACE FUNCTION getdecoder_1(id_equip_ki IN scd_equip_kits.id_equip_kits_inst%TYPE)
  
  RETURN VARCHAR2 IS
  id_equip_ki scd_equip_kits.id_contract_inst%TYPE;
  return_value VARCHAR2(100);
  agency NUMBER;
  
  BEGIN
  SELECT sc.b_agency
    INTO agency
    FROM scd_contracts sc
    JOIN scd_equip_kits sek
      ON sek.id_contract_inst = sc.id_contract_inst
     AND sek.dt_start <= current_timestamp
     AND sek.dt_stop > current_timestamp
   WHERE id_equip_ki = sek.id_equip_kits_inst;

    IF agency = 1
    THEN
    SELECT sek.v_cas_id
      INTO return_value
      FROM scd_equip_kits sek
     WHERE id_equip_ki = sek.id_equip_kits_inst;
     
    ELSIF agency = 0 
    THEN
      SELECT sek.v_ext_ident
        INTO return_value
        FROM scd_equip_kits sek
       WHERE id_equip_ki = sek.id_equip_kits_inst;
    END IF;
    
    EXCEPTION 
    WHEN OTHERS THEN 
        raise_application_error(??, 'ќборудование не найдено');
    END;
      
    RETURN return_value;
  END;


--2var
CREATE OR REPLACE FUNCTION getdecoder_1(id_equip_ki IN scd_equip_kits.id_equip_kits_inst%TYPE)
  
  RETURN VARCHAR2 IS
  id_equip_ki scd_equip_kits.id_contract_inst%TYPE;
  return_value VARCHAR2(100);
  agency NUMBER;
  
  BEGIN
  SELECT sc.id_contract_inst, sc.b_agency
    INTO id_equip_ki, agency
    FROM scd_contracts sc
    JOIN scd_equip_kits sek
      ON sek.id_contract_inst = sc.id_contract_inst
     AND sek.dt_start <= current_timestamp
     AND sek.dt_stop > current_timestamp
   WHERE id_equip_ki = sek.id_equip_kits_inst;

    IF agency = 1
    THEN
    SELECT sek.v_cas_id
      INTO return_value
      FROM scd_equip_kits sek
     WHERE id_equip_ki = sek.id_equip_kits_inst;
     
    ELSIF agency = 0 
    THEN
      SELECT sek.v_ext_ident
        INTO return_value
        FROM scd_equip_kits sek
       WHERE id_equip_ki = sek.id_equip_kits_inst;
    END IF;
    
    EXCEPTION 
       WHEN no_data_found THEN 
        raise_application_error(??, 'ќборудование не найдено');
    END;
      
    RETURN return_value;
  END;






--3

create or replace procedure getEquip(pID_EQUIP_KITS_INST in scd_equip_kits.id_equip_kits_inst%TYPE default null,
                                     dwr                 out sys_refcursor) is

begin

    if pID_EQUIP_KITS_INST is null
    then
--нужно ли делать цикл чтобы вывести все данные из таблицы?    
      open dwr for
        select distinct fc.v_long_title,
                        cu.v_username,
                        fc.v_ext_ident,
                        sekt.v_name,
                        getDecoder(sek.id_equip_kits_inst) as decoder_num
        from
            scd_equip_kits sek
               join scd_equipment_kits_type sekt on sekt.id_equip_kits_type = sek.id_equip_kits_type
                                    and sekt.dt_start <= current_timestamp
                                    and sekt.dt_stop > current_timestamp 
                join fw_contracts fc on fc.id_contract_inst = sek.id_contract_inst
                                        and fc.dt_start <= current_timestamp
                                        and fc.dt_stop > current_timestamp
                                        and fc.v_status = 'A'
                    join ci_users cu on cu.id_client_inst = fc.id_client_inst
                                            and cu.v_status = 'A' 
                        join fw_clients fcli on fcli.id_client_inst = cu.id_client_inst                     
                    
           where sek.dt_start <= current_timestamp
                    and sek.dt_stop > current_timestamp;
      
    else 
      
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
                    join ci_users cu on cu.id_client_inst = fc.id_client_inst
                                            and cu.v_status = 'A' 
                        join fw_clients fcli on fcli.id_client_inst = cu.id_client_inst                     
                                                and fcli.dt_start <= current_timestamp
                                                and fcli.dt_stop > current_timestamp
           where sek.id_equip_kits_inst = pID_EQUIP_KITS_INST
                    and sek.dt_start <= current_timestamp
                    and sek.dt_stop > current_timestamp;
           
    end if;
    exception 
       when no_data_found then 
        raise_application_error(??, 'ќборудование не найдено');
    end;
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
           
                join ci_users cu on cu.id_client_inst = fc.id_client_inst
                                        and cu.v_status = 'A' 
                    join fw_clients fcli on fcli.id_client_inst = cu.id_client_inst
                                                    and fcli.dt_start <= current_timestamp
                                                    and fcli.dt_stop > current_timestamp
                         join scd_equipment_status ses on ses.id_equipment_status = sek.id_status
                                                         and ses.b_deleted = 0
                                                         and ses.v_name != 'ѕродано'                                       
                                       
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
        set ses.v_name = 'ѕродано'
        where current of checkstatus_cursor;
        
            if agency = 1 then
                dbms_output.put_line('ƒл€ оборудовани€ '||id_equip_ki||' дилера '|| client_name|| ' с контрактом '|| ident_contract|| ', '||
                                             '€вл€ющегос€ агентской сетью был проставлен статус ѕродано.');
            else
                dbms_output.put_line('ƒл€ оборудовани€ '||id_equip_ki||' дилера '|| client_name|| ' с контрактом '|| ident_contract|| ', '||
                                             'не€вл€ющегос€ агентской сетью был проставлен статус ѕродано.');
           end if;


    end loop;

close checkstatus_cursor;
end;      
