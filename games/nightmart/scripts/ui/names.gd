class_name Names
extends RefCounted
## 꿀팁·매장 확장·발주 물건·보상 이름과 설명 문구.


static func t(key: String) -> String:
	return TranslationServer.translate(StringName(key))


static func combo(kind: int) -> String:
	return t("COMBO_%s" % Combo.Kind.keys()[kind])


static func token(token_id: StringName) -> String:
	return t("TOKEN_%s" % String(token_id).to_upper())


static func tip(tip_id: StringName) -> String:
	return t("TIP_%s" % String(tip_id).to_upper())


static func flyer(flyer_id: StringName) -> String:
	return t("FLYER_%s" % String(flyer_id).to_upper())


static func flyer_desc(flyer_id: StringName) -> String:
	return t("FLYER_%s_DESC" % String(flyer_id).to_upper())


static func expansion(exp_id: StringName) -> String:
	return t("EXP_%s" % String(exp_id).to_upper())


static func offer_name(o: Dictionary) -> String:
	match o.kind:
		Shop.TIP:
			return tip(o.id)
		Shop.EXPANSION:
			return expansion(o.id)
		Shop.PARCEL:
			return t("PARCEL_NAME") % combo(o.id)
		Shop.FLYER:
			return flyer(o.id)
	return t("PACK_NAME")


static func offer_desc(o: Dictionary) -> String:
	match o.kind:
		Shop.TIP:
			return t("TIP_%s_DESC" % String(o.id).to_upper())
		Shop.EXPANSION:
			return t("EXP_%s_DESC" % String(o.id).to_upper())
		Shop.PARCEL:
			return t("PARCEL_DESC") % combo(o.id)
		Shop.FLYER:
			return flyer_desc(o.id)
	return t("PACK_DESC")


static func money(n: int) -> String:
	return t("COUNTER_MONEY") % Style.num(n)
