//
// Copyright (C) 2001-2002 The University of Melbourne.
// This file may only be copied under the terms of the GNU Library General
// Public License - see the file COPYING.LIB in the Mercury distribution.
//

package mercury.runtime;

public class TypeCtorInfo_Struct {
    
	public int                              arity;
	public int                              type_ctor_version;
	public mercury.runtime.TypeCtorRep      type_ctor_rep;
	public int                              type_ctor_num_ptags; // if DU
	public mercury.runtime.Unify            unify_pred;
	public mercury.runtime.Compare          compare_pred;
	public java.lang.String                 type_ctor_module_name;
	public java.lang.String                 type_ctor_name;
	public mercury.runtime.TypeFunctors     type_functors;
	public mercury.runtime.TypeLayout       type_layout;
	public int 			        type_ctor_num_functors;
}
