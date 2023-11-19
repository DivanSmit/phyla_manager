%%% ====================================================================================== %%%
%%% ====================================================================================== %%%
%%% @copyright (C) 2023, Cybarete Pty Ltd
%%% @doc
%%% The base_contract module defines the functions for handling a
%%% base contract.
%%% @end
%%% ====================================================================================== %%%
%%% ====================================================================================== %%%

-module(base_contract).
-include("base_terms.hrl").
-export([
  get_partner_role/1,
  get_my_shell/1,
  get_my_promise/1,
  get_my_role/1,
  get_partner_promise/1,
  get_promise_signature/1,
  set_partner_promise/2,
  get_partner_bc/1,
  get_promise_shell/1,
  add_proposal/2,
  get_proposal/1,
  get_requirements/1,
  accept_proposal/1,
  reject_proposal/1,
  refuse_contract/1, get_proposal_bc/1, create_contract/3]).

%%% ====================================================================================== %%%
%%%                                 EXTERNAL FUNCTIONS
%%% ====================================================================================== %%%

create_contract(Requirements,MasterBC,ServantBC)->
  #base_contract{master_bc = MasterBC,servant_bc = ServantBC, requirements = Requirements, state = pending}.

get_my_role(Contract)->
  Contract#base_contract.my_role.

get_partner_role(Contract)->
  case  Contract#base_contract.my_role of
    master->
      servant;
    servant->
      master
  end.

get_my_shell(Contract)->
  case get_my_role(Contract) of
    master->
      get_master_shell(Contract);
    servant->
      get_servant_shell(Contract)
  end.

get_my_promise(Contract)->
  case get_my_role(Contract) of
    master->
      get_master_promise(Contract);
    servant->
      get_servant_promise(Contract)
  end.

get_partner_promise(Contract)->
  case get_my_role(Contract) of
    master->
      get_servant_promise(Contract);
    servant->
      get_master_promise(Contract)
  end.

get_promise_signature(P)->
  P#link_promise.signature.

set_partner_promise(Promise,Contract)->
  case get_my_role(Contract) of
    master->
      add_servant_promise(Promise,Contract);
    servant->
      add_master_promise(Promise,Contract)
  end.

get_partner_bc(Contract)->
  case get_my_role(Contract) of
    master->
      get_servant_bc(Contract);
    servant->
      get_master_bc(Contract)
  end.

get_promise_shell(Promise)->
  Promise#link_promise.shell.

get_proposal_bc({link_proposal,BC,Token,Proposal})->
  BC.

get_master_bc(Cont)->
  Promise = get_master_promise(Cont),
  Promise#link_promise.bc.

get_servant_bc(Cont)->
  Promise = get_servant_promise(Cont),
  Promise#link_promise.bc.

add_proposal(Proposal,Contract)->
  Contract#base_contract{proposal = Proposal}.

get_proposal(Contract)->
  Contract#base_contract.proposal.

get_requirements(Contract)->
  Contract#base_contract.requirements.

accept_proposal(Contract)->
  Contract#base_contract{state = accepted}.

reject_proposal(Contract)->
  Contract#base_contract{state = rejected}.

refuse_contract(Contract)->
  Contract#base_contract{state = refused}.

add_servant_promise(Pr = #link_promise{},Contract)->
  Contract#base_contract{servant_promise = Pr}.

add_master_promise(Pr = #link_promise{},Contract)->
  Contract#base_contract{master_promise = Pr}.

get_servant_shell(Contract)->
  Promise = get_servant_promise(Contract),
  Promise#link_promise.shell.

get_master_shell(Contract)->
  Promise = get_master_promise(Contract),
  Promise#link_promise.shell.

get_master_promise(Contract)->
  Contract#base_contract.master_promise.

get_servant_promise(Contract)->
  Contract#base_contract.servant_promise.