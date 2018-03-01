/** <module> a_nani_household
% This file contains the definitions for the room in a household
% To create a new world, simply change the room definitions as
% described below (or in manual)
%

use this file with...

:- ensure_loaded('a_nani_household.pfc').

*/

:- style_check(-singleton).
:- style_check(-discontiguous).

:- op(600,fx,onSpawn).

:- file_begin(pfc).

tRegion(dmiles_room).
onSpawn mudAreaConnected(dmiles_room,iHall7).

tSet(tOakDesk).
genls(tOakDesk,tFurniture).
genls(tOakDeskA,tOakDesk).
genls(tOakDeskB,tOakDesk).


onSpawn localityOfObject(tOakDeskA,dmiles_room).
onSpawn localityOfObject(tOakDeskB,dmiles_room).


