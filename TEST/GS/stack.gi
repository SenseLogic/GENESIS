#define! ImplementStack
    #get _Element_
    
    #set _ElementStack_ = @_Element_@Stack
    #set _ElementArray_ = @_Element_@Array
    
    type _ElementStack_ struct
    {
        _ElementArray_ [] _Element_;
    }
    
    func ( stack * _ElementStack_ ) Push(
        item * _Element_
        )
    {
    }
    
    func ( stack * _ElementStack_ ) Pop(
        item * _Element_
        )
    {
    }
    
    #set! stack[ _Element_ ] @= _ElementStack_
#end

#define! DeclareStack
    #get _Element_
    
    #set! stack[ _Element_ ] @= @_Element_@Stack
#end
