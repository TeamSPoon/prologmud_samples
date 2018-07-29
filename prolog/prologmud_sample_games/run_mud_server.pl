#!/usr/bin/env swipl
/* * module  MUD server startup script in SWI-Prolog

?- 
 consult(library(prologmud_sample_games/run_mud_server)).


*/
% ==============================================
% INIT LOCAL DIR
% ==============================================

:- set_prolog_flag(lm_no_autoload,false).
:- set_prolog_flag(lm_pfc_lean,false).

:- prolog_load_context(directory,D),cd(D).

:- if(current_prolog_flag(argv,[])).
:- if(\+ ((current_prolog_flag(os_argv,X),member(E,X),atom_concat('--',_,E)))).
:- set_prolog_flag('os_argv',['-l','run_mud_server.pl','--all','--pdt','--world','--repl','--lisp','--lispsock','--sumo','--planner','--cliop','--sigma','--www','--irc','--swish','--docs','--plweb','--elfinder']).
:- current_prolog_flag('os_argv',Is),writeq(set_prolog_flag('os_argv',Is)),!,nl.
:- endif.
:- endif.

:- set_prolog_stack(global, limit(32*10**9)).
:- set_prolog_stack(local, limit(32*10**9)).
:- set_prolog_stack(trail, limit(32*10**9)).
 

:- if(\+ current_predicate(setup_hist0/0)).

% ==============================================
% Enable History
% ==============================================
:- if(exists_source(library(editline))). 
:- if(\+ current_prolog_flag(windows,true)).
:- use_module(library(editline)).
:- endif.
:- else.
:- if(exists_source(library(readline))).
:- use_module(library(readline)).
:- endif.
:- endif.
setup_hist0:-  '$toplevel':setup_history.
:- setup_hist0.
:- endif.

% ==============================================
% Easier to trace while access_level system
% ==============================================
:- '$hide'('$toplevel':restore_debug).
:- '$hide'('$toplevel':save_debug).
:- '$hide'('$toplevel':residue_vars/2).
:- '$hide'('system':deterministic/1).
:- '$hide'(toplevel_call/2).
:- '$hide'('$toplevel':'$query_loop'/0).

% ==============================================
% System metapredicates
% ==============================================
:- meta_predicate '$syspreds':bit(2,?,?).
:- meta_predicate '$bags':findnsols_loop(*,*,0,*,*).
:- meta_predicate '$bags':findall_loop(*,0,*,*).
:- meta_predicate '$attvar':unfreeze(0).
:- meta_predicate '$attvar':run_crv(0,*,*,*).
:- meta_predicate '$expand':expand_term_list(4,*,*,*,*).
:- meta_predicate '$parms':cached_library_directory(*,0,*).
:- meta_predicate '$toplevel':residue_vars(0,-).
:- meta_predicate '$toplevel':toplevel_call(0).
:- meta_predicate '$toplevel':run_initialize(0,*).
% :- meta_predicate '$toplevel':run_init_goal(0,*).
% :- meta_predicate '$attvar':uhook(*,0,*,*).
% :- meta_predicate '$attvar':uhook(*,0,*).
:- meta_predicate '$toplevel':'$execute_goal2'(0,*).


% ==============================================
% Add Pack Directories
% ==============================================
:- use_module(library(prolog_pack)).
:- multifile(user:file_search_path/2).
:-   dynamic(user:file_search_path/2).

dir_from0(Rel,Y):-
    ((getenv('LOGICMOO_WS',Dir);
      prolog_load_context(directory,Dir);
      'w:/opt/logicmoo_workspace/'=Dir;      
      '~/logicmoo_workspace'=Dir;
      '/opt/logicmoo_workspace/'=Dir;
      fail)),
    absolute_file_name(Rel,Y,[relative_to(Dir),file_type(directory),file_errors(fail)]),
    exists_directory(Y),!.

add_pack_path0(packs_sys):-pack_property(pfc,_),!.
add_pack_path0(Rel):- 
   dir_from0(Rel,Y),
   (( \+ user:file_search_path(pack,Y)) ->asserta(user:file_search_path(pack,Y));true).

:- add_pack_path0(packs_sys).
:- add_pack_path0(packs_usr).
:- add_pack_path0(packs_web).
:- add_pack_path0(packs_xtra).
:- add_pack_path0(packs_lib).
:- initialization(attach_packs,now).

update_packs:-    
   use_module(library(prolog_pack)),
   (pack_property(prologmud_samples,version(Version));
    pack_property(pfc,version(Version))),!,
   use_module(library(git)),
   forall(
   (pack_property(Pack,version(Version)), pack_property(Pack,directory(Dir)),
      directory_file_path(Dir, '.git', GitDir),
      %(exists_file(GitDir);exists_directory(GitDir)),
       access_file(GitDir,read),
       access_file(GitDir,write)),
     ( print_message(informational, pack(git_fetch(Dir))),
     git([fetch], [ directory(Dir) ]),
     git_describe(V0, [ directory(Dir) ]),
     git_describe(V1, [ directory(Dir), commit('origin/master') ]),
     (   V0 == V1
     ->  print_message(informational, pack(up_to_date(Pack)))
     ;   true,
         git([merge, 'origin/master'], [ directory(Dir) ]),
         pack_rebuild(Pack)
     ))),
   initialization(attach_packs,now).

:- update_packs.

:- pack_list_installed.


% ==============================================
% SETUP KB EXTENSIONS
% ==============================================

:- '$set_typein_module'(baseKB).
:- '$set_source_module'(baseKB).

%:- setenv('DISPLAY', '').
:- use_module(library(plunit)).
:- kb_global(plunit:loading_unit/4).


:- use_module(library(logicmoo_util_startup)).

% ==============================================
% [Required] Load the Logicmoo User System
% ==============================================
:- user:load_library_system(library(logicmoo_lib)).


% ==============================================
% ============= MUD SERVER CODE LOADING =============
% ==============================================

:- if(\+ exists_source(prologmud(mud_loader))).
:- must((absolute_file_name(pack('prologmud/prolog/prologmud'),Dir),asserta(user:file_search_path(prologmud,Dir)))).
:- sanity(exists_source(prologmud(mud_loader))).
:- endif.

:- if( \+ app_argv('--noworld')).
:- baseKB:ensure_loaded(prologmud(mud_loader)).
:- endif.

% ==============================================
% ============= MUD SERVER CODE LOADED =============
% ==============================================

:- with_mpred_trace_exec(ain(isLoaded(iSourceCode7))).

:- flag_call(runtime_debug=true).

:- if((gethostname(ubuntu),fail)). % INFO this fail is so we can start faster
:- show_entry(gripe_time(40, doall(baseKB:regression_test))).
:- endif.


% ==============================================
% [Optional] Creates or suppliments a world
% ==============================================

:- if( \+ user:file_search_path(sample_games,_Dir)).
:- must((absolute_file_name(pack('prologmud_samples/prolog/prologmud_sample_games'),Dir),asserta(user:file_search_path(sample_games,Dir)))).
:- sanity(user:file_search_path(sample_games,_Dir)).
:- endif.

:- dynamic(lmconf:eachRule_Preconditional/1).
:- dynamic(lmconf:eachFact_Preconditional/1).
:- assert_setting01(lmconf:eachRule_Preconditional(true)).
:- assert_setting01(lmconf:eachFact_Preconditional(true)).

:- if(functorDeclares(mobExplorer)).

:- sanity(functorDeclares(tSourceData)).
:- sanity(functorDeclares(mobExplorer)).


==>((tCol(tLivingRoom),
 tSet(tRegion),
 tSet(tLivingRoom),

 tSet(mobExplorer),
 genls(tLivingRoom,tRegion),
 genls(tOfficeRoom,tRegion),


genlsFwd(tLivingRoom,tRegion),
genlsFwd(tOfficeRoom,tRegion),

% create some seats
mobExplorer(iExplorer1),
mobExplorer(iExplorer2),
mobExplorer(iExplorer3),
mobExplorer(iExplorer4),
mobExplorer(iExplorer5),
mobExplorer(iExplorer6),

(tHumanBody(skRelationAllExistsFn)==>{trace_or_throw(tHumanBody(skRelationAllExistsFn))}),

genls(mobExplorer,tHominid))).

:- endif.


% ==============================================
% [Required] isRuntime Hook
% ==============================================
(((localityOfObject(P,_),isRuntime)==>{if_defined(put_in_world(P))})).
:- user:use_module(library('file_scope')).
:- set_prolog_flag_until_eof(do_renames,term_expansion).



% ==============================================
% [Optional] Creates or suppliments a world
% ==============================================
:- if( \+ app_argv('--noworld')).
:- if( \+ tRegion(_)).

==> prologHybrid(mudAreaConnected(tRegion,tRegion),rtSymmetricBinaryPredicate).
==> rtArgsVerbatum(mudAreaConnected).

==>((
tRegion(iLivingRoom7),
tRegion(iOfficeRoom7),

mobExplorer(iExplorer7),
wearsClothing(iExplorer7,'iBoots773'),
wearsClothing(iExplorer7,'iCommBadge774'),
wearsClothing(iExplorer7,'iGoldUniform775'),
mudStowing(iExplorer7,'iPhaser776'))).

:- kb_shared(baseKB:tCol/1).
:- kb_shared(baseKB:ttCoercable/1).
% :- add_import_module(mpred_type_isa,baseKB,end).
onSpawn(localityOfObject(iExplorer7,tLivingRoom)).

==>((
pddlSomethingIsa('iBoots773',['tBoots','ProtectiveAttire','PortableObject','tWearAble']),
pddlSomethingIsa('iCommBadge774',['tCommBadge','ProtectiveAttire','PortableObject','tNecklace']),
pddlSomethingIsa('iGoldUniform775',['tGoldUniform','ProtectiveAttire','PortableObject','tWearAble']),
pddlSomethingIsa('iPhaser776',['tPhaser','Handgun',tWeapon,'LightingDevice','PortableObject','Device-SingleUser','tWearAble']),

mobMonster(iCommanderdata66),
mobExplorer(iCommanderdata66),
mudDescription(iCommanderdata66,txtFormatFn("Very scary looking monster named ~w",[iCommanderdata66])),
tAgent(iCommanderdata66),
tHominid(iCommanderdata66),
wearsClothing(iCommanderdata66,'iBoots673'),
wearsClothing(iCommanderdata66,'iCommBadge674'),
wearsClothing(iCommanderdata66,'iGoldUniform675'),
mudStowing(iCommanderdata66,'iPhaser676'),

pddlSomethingIsa('iBoots673',['tBoots','ProtectiveAttire','PortableObject','tWearAble']),
pddlSomethingIsa('iCommBadge674',['tCommBadge','ProtectiveAttire','PortableObject','tNecklace']),
pddlSomethingIsa('iGoldUniform675',['tGoldUniform','ProtectiveAttire','PortableObject','tWearAble']),
pddlSomethingIsa('iPhaser676',['tPhaser','Handgun',tWeapon,'LightingDevice','PortableObject','Device-SingleUser','tWearAble']))).


onSpawn(localityOfObject(iCommanderdata66,tOfficeRoom)).
onSpawn(mudAreaConnected(tLivingRoom,tOfficeRoom)).
:- endif.
:- endif.

:- if( \+ is_startup_script(_) ).
:- init_why("run_mud_server").
:- endif.


:- set_prolog_flag(access_level,system).
:- debug.



% ==============================================
% [Optionaly] Start the telent server % iCommanderdata66
% ==============================================
:- if( \+ app_argv('--nonet')).

start_telnet:- 
   user:ensure_loaded(init_mud_server),
  on_x_log_cont((call(call,start_mud_telnet))).

:- after_boot(start_telnet).

% :- assert_setting01(lmconf:eachFact_Preconditional(isRuntime)).

% [Manditory] This loads the game and initializes so test can be ran
:- baseKB:ensure_loaded(sample_games('src_game_nani/objs_misc_household.pfc')).
:- baseKB:ensure_loaded(sample_games('src_game_nani/a_nani_household.pfc')).
:- endif.

% isa(starTrek,mtHybrid).
%lst :- !.
lst :- baseKB:ensure_loaded(sample_games('src_game_startrek/?*.pfc*')).
lstr :- forall(registered_mpred_file(F),baseKB:ensure_loaded(F)).

% ==============================================
% [Optional] the following game files though can be loaded separate instead
% ==============================================
:- declare_load_dbase(sample_games('src_game_nani/?*.pfc*')).

% ==============================================
% [Optional] the following worlds are in version control in examples
% ==============================================
% :- add_game_dir(sample_games('src_game_wumpus'),prolog_repl).
% :- add_game_dir(sample_games('src_game_sims'),prolog_repl).
% :- add_game_dir(sample_games('src_game_nani'),prolog_repl).
%:- add_game_dir(sample_games('src_game_startrek'),prolog_repl).
:- declare_load_dbase(sample_games('src_game_startrek/?*.pfc*')).

%:- check_clause_counts.

:- sanity(argIsa(genlPreds,2,_)).

:- after_boot_sanity_test(argIsa(genlPreds,2,_)).


% ==============================================
% Sanity tests
% ==============================================
:- if( \+ app_argv('--noworld')).
sanity_test_ifood_rez:- ignore((
     user:ensure_loaded(init_mud_server),
     % mpred_notrace_exec,
     % flag_call(runtime_debug>true),
     ain(isa(iFoodRez2,tFood)),must(isa(iFoodRez2,tEatAble)))),
    must((call(call,parseIsa_Call(tEatAble,O,["food"],Rest)),O=iFoodRez2,Rest=[])).

:- after_boot_sanity_test((dmsg(sanity_test_ifood_rez))).


:- after_boot_sanity_test((gripe_time(1.0,must(coerce("s",vtDirection,_))))).
:- after_boot_sanity_test((gripe_time(2.0,must( \+ coerce(l,vtDirection,_))))).
:- endif.
:- after_boot_sanity_test((statistics)).
:- after_boot_sanity_test(check_clause_counts).


% ==============================================
% [Required/Optional]  Ensures...
% ==============================================

% :- after_boot(set_prolog_flag(runtime_debug,0)).
:- during_boot(set_prolog_flag(unsafe_speedups,false)).

:- if( \+ app_argv('--noworld')).
:- if(app_argv('--world')).
:- lst.
:- endif.
:- lstr.
:- endif.

lar0 :- app_argv('--repl'),!,dmsg("Ctrl-D to start MUD"),prolog,lar.
lar0 :- lar.
       
lar :- % set_prolog_flag(dmsg_level,never),
     start_runtime,
       if_defined(login_and_run,wdmsg("MUD code not loaded")).


%:- after_boot(qsave_lm(lm_init_mud)).
%:- after_boot(lar0).

:- after_boot((statistics,dmsg("Type lar.<enter> at the '?-' prompt to start the MUD (a shortcut for ?- login_and_run. )"))).

:- if(gethostname(gitlab)).                                            

:- set_prolog_flag(runtime_debug,3).
:- set_prolog_flag(runtime_safety,3).
:- set_prolog_flag(runtime_speed,0).

:- else.

:- set_prolog_flag(runtime_debug,1).
:- set_prolog_flag(runtime_safety,1).
:- set_prolog_flag(runtime_speed,1).

:- endif.

:- during_boot(ain(tSourceData(iWorldData8))).

start_runtime:- 
   ain(isLoaded(iWorldData8)),
   with_mpred_trace_exec(ain(isRuntime)).

:- after_boot(start_runtime).

%:- setenv('DISPLAY', '').
:- add_history(profile(ain(tAgent(foofy)))).
:- add_history(listing(inRegion)).
:- add_history(listing(localityOfObject)).
:- add_history(listing(mudAtLoc)).


end_of_file.
end_of_file.
end_of_file.
end_of_file.
end_of_file.
end_of_file.
end_of_file.
end_of_file.
end_of_file.
end_of_file.
end_of_file.
end_of_file.









end_of_file.
end_of_file.
end_of_file.
end_of_file.
end_of_file.

:- ensure_loaded(baseKB:library('logicmoo/common_logic/common_logic_clif.pfc')).
:- ensure_loaded(baseKB:library('logicmoo/common_logic/common_logic_sumo.pfc')).

:- kif_compile.

:- mpred_trace_all.
:- zebra0.
:- forall(trait(P),listing(P)).


% :- zebra5.
% :- rtrace.
% :- mpred_trace_exec.
%:- zebra.
%:- clif_show.

%:- break.


