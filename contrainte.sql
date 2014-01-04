-- UTILISATEUR
-- Dates de naissance invalides.
create or replace trigger naissance
    before insert or update on UTILISATEUR
    for each row
    when (sysdate < :new.dateNaissance)
BEGIN
    -- soulever une exception
    RAISE_APPLICATION_ERROR(-20200, 'La date de naissance doit etre inferieure a la date du jour.');
END;
/
ALTER TRIGGER naissance ENABLE;

-- Noms de client invalides.
create or replace trigger nom_invalide
    before insert or update on utilisateur
    for each row
    when (:new.nom not like upper(:new.nom))
BEGIN
    :new.nom := upper(:new.nom);
END;
/
ALTER TRIGGER nom_invalide ENABLE;

-- Prénoms de client invalides.
create or replace trigger prenom_invalide
    before insert or update on utilisateur
    for each row
    when (:new.prenom not like initcap(:new.prenom))
BEGIN
    :new.prenom := initcap(:new.prenom);
END;
/
ALTER TRIGGER prenom_invalide ENABLE;

-- Login invalides
create or replace trigger login_invalide
    before insert or update on utilisateur
    for each row
    when (not (regexp_like(:new.login,'^[:alpha:][:alnum:]+$')))
BEGIN
    RAISE_APPLICATION_ERROR(-20204, 'Le login est invalide ; Il doit d''abord contenir une lettre puis une suite de chiffres ou de lettres.');
END;
/
ALTER TRIGGER login_invalide ENABLE;

--Refus des ajouts de courriel de client invalide
create or replace trigger courriel_invalide
    before insert or update on utilisateur
    for each row
    when (not (regexp_like(:new.courriel,'^[:alnum:]+@[:alpha:]+\.[:alpha:]{2,}$')))
BEGIN
    RAISE_APPLICATION_ERROR(-20205, 'L''adresse courriel est invalide ; Elle doit etre du type nom@serveur.pays.');
END;
/
ALTER TRIGGER courriel_invalide ENABLE;

--Hachage du mot de passe
create or replace trigger hachage_mdp
    before insert or update on utilisateur
    for each row
BEGIN
    :new.mdp := DBMS_OBFUSCATION_TOOLKIT.MD5(input_string => :new.mdp);
END;
/
ALTER TRIGGER hachage_mdp ENABLE;

-- BIEN_IMMOBILIER
-- Date initiale
create or replace trigger insertionImmobilier
    before insert on bien_immobilier
    for each row
    when (:new.dateInitiale = NULL)
BEGIN
    :new.dateInitiale := sysdate;
END;
/
ALTER TRIGGER insertionImmobilier ENABLE;

-- RESERVATION_CRENEAU
-- Date incorrecte
create or replace trigger reserveCreneau
    before insert or update on RESERVATION_CRENEAU
    for each row
    when (sysdate > :new.dateR)
BEGIN
    RAISE_APPLICATION_ERROR(-20201, 'La date de reservation de creneau doit etre supérieure a la date du jour.');
END;
/
ALTER TRIGGER reserveCreneau ENABLE;

-- LOCATION
-- Insertion location
create or replace trigger insertion_location
    before insert or update on LOCATION
    for each row
BEGIN
    if (:new.loue = 0) then
        if ( idUtilisateur != NULL OR dateLocation != NULL ) then
            RAISE_APPLICATION_ERROR(-20211, 'Le bien n\'est pas loue, il ne peut pas etre associé à un utilisateur ou avoir une date de location.');
        end if;
    else if ( idUtilisateur = NULL OR dateLocation = NULL ) then
        RAISE_APPLICATION_ERROR(-20212, 'Le bien est loue, il doit etre associe à un utilisateur et une date de location.');
        end if;
    else if ( sysdate < :new.dateLocation ) then
        RAISE_APPLICATION_ERROR(-20202, 'La date de location doit etre inferieur a la date du jour.');
    end if;
END;
/
ALTER TRIGGER insertion_location ENABLE;

-- Suppression/Archivage
create or replace trigger archivage_location
    after delete on LOCATION
    for each row
DECLARE
    nouvelID_v HISTORIQUE_LOCATION.idHistLocation%type
BEGIN
    select count(*)
        into nouvelID_v
        from historique_location
    ;
    nouvelID := nouvelID + 1;
    insert into historique_location values
    (
        nouvelID,
        :old.idBien,
        :old.idUtilisateur,
        :old.loyer,
        :old.charges,
        :old.fraisAgence,
        :old.loue,
        :old.dateLocation,
    );
END;
/
ALTER TRIGGER archivage_location ENABLE;

-- VENTE
create or replace trigger insertion_vente
    before insert or update on VENTE
    for each row
BEGIN
    if (:new.loue = 0) then
        if ( idUtilisateur != NULL OR dateVente != NULL ) then
            RAISE_APPLICATION_ERROR(-20213, 'Le bien n\'est pas vendu, il ne peut pas etre associé à un utilisateur ou avoir une date de vente.');
        end if;
    else if ( idUtilisateur = NULL OR dateVente = NULL ) then
        RAISE_APPLICATION_ERROR(-20214, 'Le bien est vendu, il doit etre associe à un utilisateur et une date de location.');
        end if;
    else if ( sysdate < :new.dateVente ) then
        RAISE_APPLICATION_ERROR(-20215, 'La date de vente doit etre inferieur a la date du jour.');
    end if;
END;
/
ALTER TRIGGER insertion_vente ENABLE;

-- Suppression/Archivage
create or replace trigger archivage_vente
    after delete on VENTE
    for each row
DECLARE
    nouvelID_v HISTORIQUE_VENTE.idHistVente%type
BEGIN
    select count(*)
        into nouvelID_v
        from historique_vente
    ;
    nouvelID := nouvelID + 1;
    insert into historique_vente values
    (
        nouvelID,
        :old.idBien,
        :old.idUtilisateur,
        :old.prixInitial,
        :old.prixCourant,
        :old.fraisAgence,
        :old.vendu,
        :old.dateVente,
        :old.prixCourant * :old.fraisAgence
    );
END;
/
ALTER TRIGGER archivage_vente ENABLE;

-- HISTORIQUE_LOCATION
create or replace trigger insertion_historique_location
    before insert or update on HISTORIQUE_LOCATION
    for each row
BEGIN
    if (:new.loue = 0) then
        if ( idUtilisateur != NULL OR dateLocation != NULL ) then
            RAISE_APPLICATION_ERROR(-20216, 'Le bien n\'est pas loue, il ne peut pas etre associé à un utilisateur ou avoir une date de location.');
        end if;
    else if ( idUtilisateur = NULL OR dateLocation = NULL ) then
        RAISE_APPLICATION_ERROR(-20217, 'Le bien est loue, il doit etre associe à un utilisateur et une date de location.');
        end if;
    else if ( sysdate < :new.dateLocation ) then
        RAISE_APPLICATION_ERROR(-20218, 'La date de location doit etre inferieur a la date du jour.');
    end if;
END;
/
ALTER TRIGGER insertion_historique_location ENABLE;

-- HISTORIQUE_VENTE
create or replace trigger insertion_historique_vente
    before insert or update on HISTORIQUE_VENTE
    for each row
BEGIN
    if (:new.loue = 0) then
        if ( idUtilisateur != NULL OR dateVente != NULL ) then
            RAISE_APPLICATION_ERROR(-20219, 'Le bien n\'est pas vendu, il ne peut pas etre associé à un utilisateur ou avoir une date de vente.');
        end if;
    else if ( idUtilisateur = NULL OR dateVente = NULL ) then
        RAISE_APPLICATION_ERROR(-20220, 'Le bien est vendu, il doit etre associe à un utilisateur et une date de location.');
        end if;
    else if ( sysdate < :new.dateVente ) then
        RAISE_APPLICATION_ERROR(-20221, 'La date de vente doit etre inferieur a la date du jour.');
        end if;
    else if ( :new.benefice != :new.prixVente * :new.fraisAgence ) then
        RAISE_APPLICATION_ERROR(-20222, 'Bénéfice invalide.');
        end if;
    end if;
END;
/
ALTER TRIGGER insertion_historique_vente ENABLE;

create or replace trigger visite_invalide
before insert on reservation_creneau
for each row
DECLARE
  jour_de_la_semaine varchar(10);
  nombre_de_reservation integer;

  cursor liste_creneau_agent_c is
    select idPersonnel, idBien, dateR, duree
    from reservation_creneau natural join relations_client;

  cursor liste_creneau_client_c is
    select idUtilisateur, idBien, dateR, duree
    from reservation_creneau;

BEGIN
  select upper(to_char(:new.dateR, 'DAY'))
  into jour_de_la_semaine
  from dual;

  --Si la réservation est un dimanche on soulève une excpetion
  if (jour_de_la_semaine like 'SUNDAY') then
    raise_application_error(-20206, 'Rerservation non autorisee le dimanche.');
  end if;

  select count(*)
  into nombre_de_reservation
  from reservation_creneau rc
  where :new.dateR = rc.dateR;

  --Si le nombre de réservation est supérieur à 2 alors on empèche la réservation
  if (nombre_de_reservation > 3=) then
    raise_application_error(-20207, 'Il y a deja 3 reservations le jour la.');
  end if;

  --Si l'heure de la réservation n'est pas comprise entre 8 et 20 alors on empèche la réservation
  if (to_number(to_char(:new.dateR,hh24))<8 || (to_number(to_char(:new.dateR,hh24))+duree/60)>20) then
    raise_application_error(-20208, 'La reservation doit commencer à partir de 8h et finir avant 20h.');
  end if;

  for agent_r in liste_creneau_agent_c loop
  --Si un agent se trouve à deux endroits en meme temps
    if (:new.idPersonnel=agent_r.idPersonnel
    AND :new.idBien!=agent_r.idBien
    AND not ((:new.dateR<agent_r.dateR AND :new.dateR+:new.duree<agent_r.dateR+agent_r.duree
            OR :new.dateR>agent_r.dateR AND :new.dateR+:new.duree>agent_r.dateR+agent_r.duree)
            )
    )then
      raise_application_error(-20209, 'Un agent ne peut se trouver a deux endroits en meme temps.');
    end if;
  end loop;

  for client_r in liste_creneau_client_c loop
  --Si un client se trouve à deux endroits en meme temps
    if (:new.idUtilisateur=client_r.idUtilisateur
    AND :new.idBien!=client_r.idBien
    AND not ((:new.dateR<client_r.dateR AND :new.dateR+:new.duree<client_r.dateR+client_r.duree
            OR :new.dateR>client_r.dateR AND :new.dateR+:new.duree>client_r.dateR+client_r.duree)
            )
    )then
      raise_application_error(-20210, 'Un client ne peut se trouver a deux endroits en meme temps.');
    end if;
  end loop;
END;
/
ALTER TRIGGER visite_invalide ENABLE;

create view pourcentage_rentabilite (identifiant_bien, rentabilite, prix) as
  select idBien, ((prixCourant/prixInitial)*100), prixCourant
  from vente;
--On autorise les gens à modifier le prix et sélectionner n'importe quoi dans la vue
grant select, update(prix) on pourcentage_rentabilite to public;
