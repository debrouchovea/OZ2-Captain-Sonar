functor
import
   Input

   OS %rand
   %System %debug
   %Browser %debug
export
   portPlayer:StartPlayer
define
   StartPlayer
   TreatStream

   InitState
   UpdateState
   MapRandomPos
   MapIsWater

   InitPosition
   Move
   Dive
   ChargeItem
   FireItem
   FireMine
   IsSurface
   SayMove
   SaySurface
   SayCharge
   SayMinePlaced
   SayMissileExplode
   SayMineExplode
   SayPassingDrone
   SayAnswerDrone
   SayPassingSonar
   SayAnswerSonar
   SayDeath
   SayDamageTaken
   CanMove
   RandomMove
   SmartMove
in
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   fun{InitState ID Color}
      fun{InitEnemies State N} NewState StateEn in
	 if N == 0 then
	    State
	 else
	    %Personnaliser le State de départ de chaque ennemi ici
	    StateEn = {UpdateState State.enemies [N#enemy(pos:null xtrue:0 ytrue:0)]}
	    NewState = {UpdateState State [enemies#StateEn]}
	    {InitEnemies NewState N-1}
	 end
      end
      MidState
      NewState
   in
      %Personnaliser le State de départ ici
      MidState = state(
		    id:id(id:ID color:Color name:'Smart1')
		    hp:Input.maxDamage
		    missileCharge:0
		    mineCharge:0
		    sonarCharge:0
		    droneCharge:0
		    enemies:data(1:null)
		    surf:true
		    surfCharge:0
		    visited:nil
		    lastDir:null
		    focus:null
		    xsure:xsure(1:null)
		    ysure:ysure(1:null)
		    )
      NewState = {InitEnemies MidState Input.nbPlayer}
      NewState
   end

   %Update un State avec une liste de tuple contenant les valeurs qui ont changé
   % state(a:1 b:2) + [b#3] = state(a:1 b:3)
   fun{UpdateState State L}
      {AdjoinList State L}
   end

%%%%%%%%%%%%%%%%%

   %Fonctions lancées à la réception des messages
   %Elles représentent le comportement du Sub

   %Choisit une position de départ
   fun{InitPosition State ID Position}
      fun{NewPos}
	 fun{MapRandomPos}
	    pt(x:({OS.rand} mod Input.nRow + 1) y:({OS.rand} mod Input.nColumn + 1))
	 end
	 fun{MapIsWater Pos}
	    if {List.nth {List.nth Input.map Pos.x} Pos.y} == 0 then
	       true
	    else
	       false
	    end
	 end
	 Pos
      in
	 Pos = {MapRandomPos}
	 if {MapIsWater Pos} then
	    Pos
	 else
	    {NewPos}
	 end
      end
      NewState
      RetPos
   in
      RetPos = {NewPos}
      NewState = {UpdateState State [visited#[RetPos] pos#RetPos]}
      ID = NewState.id
      Position = NewState.pos
      NewState
   end

%%%
   fun{CanMove State Pos}
      fun{Visited State Pos}
	 fun{Check L Pos}
	    case L
	    of nil then false
	    []pt(x:X y:Y)|T then
	       if Pos.x == X andthen Pos.y == Y then
		  true
	       else
		  {Check T Pos}
	       end
	    end
	 end
      in
	 {Check State.visited Pos}
      end
      if Pos.x>0 andthen Pos.x=<Input.nRow andthen Pos.y>0 andthen Pos.y=<Input.nColumn andthen  {List.nth {List.nth Input.map Pos.x} Pos.y} == 0 andthen {Visited State Pos} == false then
	 true
      else
	 false
      end
   end

   fun{RandomMove State Pos}
      fun{SubRandom Try Pos}
	 if Try == 0 then
	    null
	 else Rand in
	    Rand = {OS.rand} mod 4
	    case Rand
	    of 0 then
	       if {CanMove State pt(x:Pos.x+1 y:Pos.y)} then
		  move(south pt(x:Pos.x+1 y:Pos.y))
	       else
		  {SubRandom Try-1 Pos}
	       end
	    [] 1 then
	       if {CanMove State pt(x:Pos.x-1 y:Pos.y)} then
		  move(north pt(x:Pos.x-1 y:Pos.y))
	       else
		  {SubRandom Try-1 Pos}
	       end
	    [] 2 then
	       if {CanMove State pt(x:Pos.x y:Pos.y-1)} then
		  move(west pt(x:Pos.x y:Pos.y-1))
	       else
		  {SubRandom Try-1 Pos}
	       end
	    [] 3 then
	       if {CanMove State pt(x:Pos.x y:Pos.y+1)} then
		  move(east pt(x:Pos.x y:Pos.y+1))
	       else
		  {SubRandom Try-1 Pos}
	       end
	    end
	 end
      end
   end

   fun {SmartMove State Position} D N Xn Yn DistX DistY in
      if State.focus \= null then
	 N = State.focus
	 Xn = State.enemies.N.pos.x
	 Yn = State.enemies.N.pos.y
	 D = {OS.rand} mod 2
	 DistX = {Number.abs Position.x - Xn}
	 DistY = {Number.abs Position.y - Yn}
	 if DistX==0 then
	    if (Position.x - Xn) < 0 then
	       if {CanMove State pt(x:Position.x+1 y:Position.y)} then
		  move(south pt(x:Position.x+1 y:Position.y))
	       else
		  if {List.nth {List.nth Input.map Pos.x+1} Pos.y} == 0 then
		     surface
		  else
		     if {CanMove State pt(x:Pos.x y:Pos.y-1)} then
			move(west pt(x:Pos.x y:Pos.y-1))
		     elseif {CanMove State pt(x:Pos.x y:Pos.y+1)} then
			move(east pt(x:Pos.x y:Pos.y+1))
		     elseif{CanMove State pt(x:Pos.x-1 y:Pos.y)} then
			move(north pt(x:Pos.x-1 y:Pos.y))
		     end
		  end
	       end
	    else
	       if {CanMove State pt(x:Position.x-1 y:Position.y)} then
		  move(north pt(x:Position.x-1 y:Position.y))
	       else
		  if {List.nth {List.nth Input.map Pos.x-1} Pos.y} == 0 then
		     surface
		  else
		     if {CanMove State pt(x:Pos.x y:Pos.y-1)} then
			move(west pt(x:Pos.x y:Pos.y-1))
		     elseif {CanMove State pt(x:Pos.x y:Pos.y+1)} then
			move(east pt(x:Pos.x y:Pos.y+1))
		     else{CanMove State pt(x:Pos.x-1 y:Pos.y)} then
			move(south pt(x:Pos.x+1 y:Pos.y))
		     end
		  end
	       end
	    end
	 elseif DistY==0 then
	    if (Position.x - Xn) < 0 then
	       if {CanMove State pt(x:Position.x y:Position.y+1)} then
		  move(east pt(x:Position.x y:Position.y+1))
	       else
		  if {List.nth {List.nth Input.map Pos.x} Pos.y+1} == 0 then
		     surface
		  else
		     if {CanMove State pt(x:Pos.x-1 y:Pos.y)} then
			move(north pt(x:Pos.x-1 y:Pos.y))
		     elseif {CanMove State pt(x:Pos.x+1 y:Pos.y)} then
			move(south pt(x:Pos.x+1 y:Pos.y))
		     elseif{CanMove State pt(x:Pos.x y:Pos.y-1)} then
			move(west pt(x:Pos.x y:Pos.y-1))
		     end
		  end
	       end
	    else
	       if {CanMove State pt(x:Position.x-1 y:Position.y)} then
		  move(north pt(x:Position.x-1 y:Position.y))
	       else
		  if {List.nth {List.nth Input.map Pos.x-1} Pos.y} == 0 then
		     surface
		  else
		     if {CanMove State pt(x:Pos.x y:Pos.y-1)} then
			move(west pt(x:Pos.x y:Pos.y-1))
		     elseif {CanMove State pt(x:Pos.x y:Pos.y+1)} then
			move(east pt(x:Pos.x y:Pos.y+1))
		     else{CanMove State pt(x:Pos.x-1 y:Pos.y)} then
			move(south pt(x:Pos.x+1 y:Pos.y))
		     end
		  end
	       end
	    end
	 else
	    if DistX > DistY then
	       if (Position.x - Xn) < 0 then
		  if {CanMove State pt(x:Position.x+1 y:Position.y)} then
		     move(south pt(x:Position.x+1 y:Position.y))
		  else
		     if {List.nth {List.nth Input.map Pos.x+1} Pos.y} == 0 then
			surface
		     else
			if {CanMove State pt(x:Pos.x y:Pos.y-1)} then
			   move(west pt(x:Pos.x y:Pos.y-1))
			elseif {CanMove State pt(x:Pos.x y:Pos.y+1)} then
			   move(east pt(x:Pos.x y:Pos.y+1))
			elseif{CanMove State pt(x:Pos.x-1 y:Pos.y)} then
			   move(north pt(x:Pos.x-1 y:Pos.y))
			end
		     end
		  end
	       else
		  if {CanMove State pt(x:Position.x-1 y:Position.y)} then
		     move(north pt(x:Position.x-1 y:Position.y))
		  else
		     if {List.nth {List.nth Input.map Pos.x-1} Pos.y} == 0 then
			surface
		     else
			if {CanMove State pt(x:Pos.x y:Pos.y-1)} then
			   move(west pt(x:Pos.x y:Pos.y-1))
			elseif {CanMove State pt(x:Pos.x y:Pos.y+1)} then
			   move(east pt(x:Pos.x y:Pos.y+1))
			else{CanMove State pt(x:Pos.x-1 y:Pos.y)} then
			   move(south pt(x:Pos.x+1 y:Pos.y))
			end
		     end
		  end
	       end
	    else
	       if (Position.x - Xn) < 0 then
		  if {CanMove State pt(x:Position.x y:Position.y+1)} then
		     move(east pt(x:Position.x y:Position.y+1))
		  else
		     if {List.nth {List.nth Input.map Pos.x} Pos.y+1} == 0 then
			surface
		     else
			if {CanMove State pt(x:Pos.x-1 y:Pos.y)} then
			   move(north pt(x:Pos.x-1 y:Pos.y))
			elseif {CanMove State pt(x:Pos.x+1 y:Pos.y)} then
			   move(south pt(x:Pos.x+1 y:Pos.y))
			elseif{CanMove State pt(x:Pos.x y:Pos.y-1)} then
			   move(west pt(x:Pos.x y:Pos.y-1))
			end
		     end
		  end
	       else
		  if {CanMove State pt(x:Position.x-1 y:Position.y)} then
		     move(north pt(x:Position.x-1 y:Position.y))
		  else
		     if {List.nth {List.nth Input.map Pos.x-1} Pos.y} == 0 then
			surface
		     else
			if {CanMove State pt(x:Pos.x y:Pos.y-1)} then
			   move(west pt(x:Pos.x y:Pos.y-1))
			elseif {CanMove State pt(x:Pos.x y:Pos.y+1)} then
			   move(east pt(x:Pos.x y:Pos.y+1))
			else{CanMove State pt(x:Pos.x-1 y:Pos.y)} then
			   move(south pt(x:Pos.x+1 y:Pos.y))
			end
		     end
		  end
	       end
	    end
	 end
      else
	 {RandomMove State Position}
      end
   end

   fun{Move State Position} Msg NewState Ret in
      Msg = {SmartMove State Position}
      if Msg==surface orelse Msg==null then
	 NewState = {UpdateState State [surf#true visited#[State.visited.1]]}
	 Ret = ret(surface NewState)
      else
	 case Msg of move(Dir NewPos)
	    NewState = {UpdateState State [pos#NewPos visited#(NewPos|State.visited)]}
	    Ret = ret(Dir NewState)
	 end
      end
      {Browser.browse State.visited}
      case Ret
      of ret(NewDir NewState) then
	 Direction = NewDir
	 Position = NewState.pos
	 ID = NewState.id
	 NewState
      end
   end
%%%

   %Donne au Sub la permission de replonger
   fun{Dive State} NewState in
      NewState = {UpdateState State [surf#false]}
      NewState
   end

%%%

   %Donne au Sub la permission de charger un item de son choix
   % A COMPLETER
   fun{ChargeItem State ID KindItem} NewState in
      NewState = State
      ID = NewState.id
      KindItem = null
      NewState
   end

%%%

   %Donne au Sub la permission de tirer un item de son choix (missile, sonar, drone)
   % A COMPLETER
   fun{FireItem State ID KindFire} NewState in
      NewState = State
      KindFire = null
      ID = NewState.id
      NewState
   end

%%%

   %Donne au Sub la permission de tirer une mine
   % A COMPLETER
   fun{FireMine State ID Mine} NewState in
      NewState = State
      ID = NewState.id
      Mine = null
      State
   end

%%%

   %Demande au Sub s'il est en surface
   fun{IsSurface State ID Answer}
      ID = State.id
      Answer = State.surf
      State
   end

%%%

   %Dit au Sub qu'un Sub a bougé
   % Verif si ne sort pas de la map sinon considere position fausse
   % init focus si sur de position
   fun{SayMove State ID Direction} N StateN StateEn NewState Npos YS XS R Dist DistFocus in
      N = ID.id
      YS = null
      XS = null
      if ID \= State.id then
	 Npos = State.enemies.N.pos
	 if Npos \= null then
	    case Direction
	    of north then
	       if State.enemies.N.x+1 <= Input.NRow then
		  StateN = {UpdateState State.enemies.N [pos#State.enemies.N.x+1]}
	       else
		  YS = true
		  XS = false
	       end
	    [] south then
	       if State.enemies.N.x-1 > 0 then
		  StateN = {UpdateState State.enemies.N [pos#State.enemies.N.x-1]}
	       else
		  YS = true
		  XS = false
	       end
	    [] east then
	       if State.enemies.N.y+1 <= Input.NColumn then
		  StateN = {UpdateState State.enemies.N [pos#State.enemies.N.y+1]}
	       else
		  XS = true
		  YS = false
	       end
	    [] west then
	       if State.enemies.N.x-1 > 0 then
		  StateN = {UpdateState State.enemies.N [pos#State.enemies.N.y-1]}
	       else
		  XS = true
		  YS = false
	       end
	    end
	    if XS \= null then
	       {UpdateState State.xsure [N#XS]}
	       {UpdateState State.ysure [N#YS]}
	    end
	    StateEn = {UpdateState State.enemies [N#StateN]}
	    if State.xsure.N == true andthen State.ysure.N == true then
	       if State.focus==null then
		  NewState = {UpdateState State [focus#N enemies#StateEn]}
	       else
		  DistFocus = {Number.abs State.ennemis.(State.focus).pos.x - State.pos.x} + {Number.abs State.ennemis.(State.focus).pos.y - State.pos.y}
		  Dist = {Number.abs State.ennemis.N.pos.x - State.pos.x} + {Number.abs State.ennemis.N.pos.y - State.pos.y}
		  if Dist < DistFocus then
		     NewState = {UpdateState State [focus#N enemies#StateEn]}
		  end
	       end
	    else
	       NewState = {UpdateState State [enemies#StateEn]}
	    end
	 else
	    NewState = State
	 end
      else
	 NewState = State
      end
      NewState
   end

%%%

   %Dit au Sub qu'un Sub a fait surface
   % A COMPLETER
   fun{SaySurface State ID}
   %A priori on s'en bat les couilles
      State
   end

%%%

   %Dit au Sub qu'un Sub a fini de charger un item
   % A COMPLETER
   fun{SayCharge State ID KindItem}
   %A priori on s'en bat les couilles
      State
   end

%%%

   %Dit au Sub qu'une mine a été placée
   % A COMPLETER
   fun{SayMinePlaced State ID}
   %A priori on s'en bat les couilles
      State
   end

%%%

   %Annonce l'explosion d'un missile, le Sub doit dire s'il a été touché
   fun{SayMissileExplode State ID Position Message}
      fun{DistToSub State Pos}
	 {Number.abs State.pos.x - Pos.x} + {Number.abs State.pos.y - Pos.y}
      end
      NewState
      MidState
      Dist
   in
      Dist = {DistToSub State Position}
      if Dist == 0 then
	 MidState = {UpdateState State [hp#(State.hp-2)]}
      elseif Dist == 1 then
	 MidState = {UpdateState State [hp#(State.hp-1)]}
      else
	 MidState = State
	 NewState = State
      end
      if State.hp \= MidState.hp then
	 if MidState.hp =< 0 then
	    Message = sayDeath(State.id)
	    NewState = {UpdateState MidState [dead#true hp#0]}
	 else
	    Message = sayDamageTaken(State.id State.hp-MidState.hp MidState.hp)
	    NewState = MidState
	 end
      else
	 Message = null
      end
      NewState
   end

%%%

   %Annonce l'explosion d'une mine, le Sub doit dire s'il a été touché
   fun{SayMineExplode State ID Position Message}
      fun{DistToSub State Pos}
	 {Number.abs State.pos.x - Pos.x} + {Number.abs State.pos.y - Pos.y}
      end
      NewState
      MidState
      Dist
   in
      Dist = {DistToSub State Position}
      if Dist == 0 then
	 MidState = {UpdateState State [hp#(State.hp-2)]}
      elseif Dist == 1 then
	 MidState = {UpdateState State [hp#(State.hp-1)]}
      else
	 MidState = State
	 NewState = State
      end
      if State.hp \= MidState.hp then
	 if MidState.hp =< 0 then
	    Message = sayDeath(State.ID)
	    NewState = {UpdateState MidState [dead#true hp#0]}
	 else
	    Message = sayDamageTaken(State.ID State.hp-MidState.hp MidState.hp)
	    NewState = MidState
	 end
      else
	 Message = null
      end
      NewState
   end

%%%

   %Annonce le passage d'un drone, le Sub doit y répondre
   fun{SayPassingDrone State Drone ID Answer}
      case Drone
      of drone(row X) then
	 if State.pos.x == X then
	    Answer = true
	 else
	    Answer = false
	 end
      [] drone(column Y) then
	 if State.pos.y == Y then
	    Answer = true
	 else
	    Answer = false
	 end
      end
      ID = State.id
      State
   end

%%%

   %Réponse au drone que l'on a lancé
   fun{SayAnswerDrone State Drone ID Answer} StateN StateEn NewState in
      case Drone
      of drone(row X) then
	 if Answer == true then
	    if ID \= State.id then
	       StateN = {UpdateState State.enemies.(ID.id) [pos#Answer xsure#true ysure#false xtrue#State.xtrue+1]}
	       StateEn = {UpdateState State.enemies [ID.id#StateN] }
	       NewState = {UpdateState State}
	       NewState
	    end
	 end
      []drone(column Y) then
	 if Answer == true then
	    if ID \= State.id then
	       StateN = {UpdateState State.enemies.(ID.id) [pos#Answer xsure#false ysure#true ytrue#State.ytrue+1]}
	       StateEn = {UpdateState State.enemies [ID.id#StateN] }
	       NewState = {UpdateState State}
	       NewState
	    end
	 end
      end
   end

%%%

   %Annonce le passage d'un sonar, le Sub doit y répondre
   fun{SayPassingSonar State ID Answer}
      ID = State.id
         %On donnera la position x exacte, mais la mauvaise position y (random), par exemple
      Answer = pt(x:State.pos.x y:({OS.rand} mod Input.nColumn + 1))
      State
   end

%%%

   %Réponse au sonar que l'on a lancé
   fun{SayAnswerSonar State ID Answer} StateN StateEn NewState N X Y in
      N = ID.id
      if N \= State.id then
	 StateN = {UpdateState State.enemies.N [pos#Answer]}
	 StateEn = {UpdateState State.enemies [N#StateN]}
	 if State.xsure \= true then
	    X = {UpdateState State.xsure [N#false]}
	 end
	 if State.ysure \= true then
	    Y = {UpdateState State.ysure [N#false]}
	 end
	 NewState = {UpdateState State [enemies#StateEn xsure#X ysure#Y]}
	 NewState
      else
	 State
      end
   end

%%%

   %Dit au Sub qu'un Sub est mort
   fun{SayDeath State ID} StateEn X Y NewState in
      StateEn = {Record.subtract State.enemies ID}
      X = {Record.subtract State.xsure ID}
      Y = {Record.subtract State.ysure ID}
      if State.focus == ID then
	 NewState = {UpdateState State [enemies#StateEn focus#null X Y]}
      else
	 NewState = {UpdateState State [enemies#StateEn X Y]}
      end
   end

%%%

   %Dit au Sub qu'un Sub a pris des dégâts
   fun{SayDamageTaken State ID Damage LifeLeft}
      %Ne rien faire on ne fait pas attention au hp des autres
      State
   end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   fun{StartPlayer Color ID}
      Stream
      Port
      State
   in
      Port = {NewPort Stream}
      thread
	 State = {InitState ID Color}
	 {TreatStream Stream State}
      end
      Port
   end

   proc{TreatStream Stream State}
      %Le State va être la mémoire du Sub, qui sera modifiée selon le message reçu
      %Pv, position, munitions, ennemis, ...

      case Stream
      of nil then skip
      []initPosition(ID Position)|S then NewState in
	 NewState = {InitPosition State ID Position}
	 {TreatStream S NewState}
      []move(ID Position Direction)|S then NewState in
	 NewState = {Move State ID Position Direction}
	 {TreatStream S NewState}
      []dive|S then NewState in
	 NewState = {Dive State}
	 {TreatStream S NewState}
      []chargeItem(ID KindItem)|S then NewState in
	 NewState = {ChargeItem State ID KindItem}
	 {TreatStream S NewState}
      []fireItem(ID KindFire)|S then NewState in
	 NewState = {FireItem State ID KindFire}
	 {TreatStream S NewState}
      []fireMine(ID Mine)|S then NewState in
	 NewState = {FireMine State ID Mine}
	 {TreatStream S NewState}
      []isSurface(ID Answer)|S then NewState in
	 NewState = {IsSurface State ID Answer}
	 {TreatStream S NewState}
      []sayMove(ID Direction)|S then NewState in
	 NewState = {SayMove State ID Direction}
	 {TreatStream S NewState}
      []saySurface(ID)|S then NewState in
	 NewState = {SaySurface State ID}
	 {TreatStream S NewState}
      []sayCharge(ID KindItem)|S then NewState in
	 NewState = {SayCharge State ID KindItem}
	 {TreatStream S NewState}
      []sayMinePlaced(ID)|S then NewState in
	 NewState = {SayMinePlaced State ID}
	 {TreatStream S NewState}
      []sayMissileExplode(ID Position Message)|S then NewState in
	 NewState = {SayMissileExplode State ID Position Message}
	 {TreatStream S NewState}
      []sayMineExplode(ID Position Message)|S then NewState in
	 NewState = {SayMineExplode State ID Position Message}
	 {TreatStream S NewState}
      []sayPassingDrone(Drone ID Answer)|S then NewState in
	 NewState = {SayPassingDrone State Drone ID Answer}
	 {TreatStream S NewState}
      []sayAnswerDrone(Drone ID Answer)|S then NewState in
	 NewState = {SayAnswerDrone State Drone ID Answer}
	 {TreatStream S NewState}
      []sayPassingSonar(ID Answer)|S then NewState in
	 NewState = {SayPassingSonar State ID Answer}
	 {TreatStream S NewState}
      []sayAnswerSonar(ID Answer)|S then NewState in
	 NewState = {SayAnswerSonar State ID Answer}
	 {TreatStream S NewState}
      []sayDeath(ID)|S then NewState in
	 NewState = {SayDeath State ID}
	 {TreatStream S NewState}
      []sayDamageTaken(ID Damage LifeLeft)|S then NewState in
	 NewState = {SayDamageTaken State ID Damage LifeLeft}
	 {TreatStream S NewState}
      else
	 skip
      end
   end
end